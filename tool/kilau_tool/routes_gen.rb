require_relative "template_compile"

module KilauTool
  # `kilau gen routes <app-dir>` (spec §2.2 fallback): reads the route
  # declarations in <app-dir>/src/**/*.rb and writes build/gen/routes.rb, a
  # dispatcher that calls every handler body directly instead of through
  # the stored proc of an Endpoint (K-012). The app's code is unchanged; a
  # second entry point uses Routed<Hooks>.new instead of <Hooks>.new.
  #
  # The generator reads source text, not Ruby semantics, so it accepts one
  # shape and refuses anything else with file:line:
  # - a route is one line: .add("path", verb { |a, b| body })
  # - a controller's group is `Kilau::Routes.new` in `def self.routes`
  # - the app composes in one line: Kilau::AppRoutes.with_default_routes
  #   .add(local).add(Controller.routes), where local = Kilau::Routes.new...
  #   in the same method
  # - classes that declare routes are top level
  module RoutesGen
    VERBS = { "get" => "GET", "post" => "POST", "patch" => "PATCH", "delete" => "DELETE" }
    DEFAULTS = [["GET", "/_ping", "Kilau::AppRoutes.ping"], ["GET", "/_health", "Kilau::AppRoutes.health"]]

    class Decl
      attr_reader :verb, :pattern, :klass, :params, :body, :where

      def initialize(verb, pattern, klass, params, body, where)
        @verb = verb
        @pattern = pattern
        @klass = klass
        @params = params
        @body = body
        @where = where
      end
    end

    class Group
      attr_reader :decls
      attr_accessor :prefix

      def initialize
        @prefix = ""
        @decls = []
      end
    end

    # What the scan of every file found.
    class Scan
      attr_reader :groups, :composition
      attr_accessor :hooks_class, :composition_where

      def initialize
        @groups = {}
        @composition = []
        @hooks_class = ""
        @composition_where = ""
      end
    end

    def self.generate(app_dir)
      src = "#{app_dir}/src"
      raise ArgumentError, "no source directory at #{src}" unless File.directory?(src)
      scan = Scan.new
      Dir.glob("#{src}/**/*.rb").sort.each do |file|
        scan_file(file[app_dir.size + 1, file.size - app_dir.size - 1], File.read(file), scan)
      end
      source = render(scan)
      build = "#{app_dir}/build"
      gen = "#{build}/gen"
      Dir.mkdir(build) unless File.directory?(build)
      Dir.mkdir(gen) unless File.directory?(gen)
      path = "#{gen}/routes.rb"
      File.write(path, source)
      path
    end

    def self.scan_file(path, source, scan)
      klass = ""
      method_owner = ""
      method_indent = -1
      current = ""
      source.split("\n", -1).each_with_index do |line, i|
        where = "#{path}:#{i + 1}"
        text = line.strip
        indent = line.size - line.lstrip.size
        if text.start_with?("class ")
          name = text[6, text.size - 6].split(" ")[0].to_s
          klass = indent == 0 ? name : ""
        end
        if method_indent >= 0 && indent == method_indent && text == "end"
          method_indent = -1
        elsif text == "def self.routes" || text == "def routes"
          raise ArgumentError, "#{where}: gen routes needs routes declared in a top-level class" if klass.empty?
          method_owner = klass
          method_indent = indent
          current = ""
        elsif text.start_with?("def self.routes = ") || text.start_with?("def routes = ")
          raise ArgumentError, "#{where}: gen routes needs routes declared in a top-level class" if klass.empty?
          current = scan_line(text[text.index("= ") + 2, text.size], klass, "", where, scan)
        elsif method_indent >= 0
          current = scan_line(text, method_owner, current, where, scan)
        end
      end
    end

    # One line of a routes method. current: the key of the group the line
    # continues, "" if none. Returns the key the next line continues.
    def self.scan_line(text, owner, current, where, scan)
      key = current
      at = text.index("Kilau::Routes.new")
      unless at.nil?
        eq = text.index(" = ")
        key = !eq.nil? && eq < at ? "#{owner}##{text[0, eq].strip}" : "#{owner}.routes"
        scan.groups[key] = Group.new
      end
      if text.include?("Kilau::AppRoutes.with_default_routes")
        raise ArgumentError, "#{where}: a second Kilau::AppRoutes.with_default_routes" unless scan.hooks_class.empty?
        scan.hooks_class = owner
        scan.composition_where = where
        compose(text[text.index("with_default_routes") + 19, text.size], owner, where, scan)
        return key
      end
      prefix_at = text.index(".prefix(")
      unless prefix_at.nil?
        raise ArgumentError, "#{where}: .prefix outside a Kilau::Routes.new chain" if key.empty?
        name = string_at(text, prefix_at + 8, where)
        trimmed = name.split("/").reject { |segment| segment.empty? }.join("/")
        scan.groups[key].prefix = trimmed.empty? ? "" : "/" + trimmed
      end
      pos = text.index(".add(")
      until pos.nil?
        raise ArgumentError, "#{where}: .add outside a Kilau::Routes.new chain" if key.empty?
        pos = add_route(text, pos + 5, owner, scan.groups[key], where)
        pos = text.index(".add(", pos)
      end
      key
    end

    # .add("path", [Kilau::Controller.]verb { |a, b| body }) starting after
    # ".add(". Returns the index after its closing ")".
    def self.add_route(text, pos, owner, group, where)
      path = string_at(text, pos, where)
      i = skip_space(text, text.index("\"", pos + 1) + 1)
      raise ArgumentError, "#{where}: expected , after the route path" unless text[i] == ","
      i = skip_space(text, i + 1)
      ["Kilau::Controller.", "Controller.", "self."].each do |qualifier|
        i += qualifier.size if text[i, qualifier.size] == qualifier
      end
      start = i
      i += 1 while i < text.size && Template.word_char?(text[i])
      word = text[start, i - start]
      raise ArgumentError, "#{where}: expected get, post, patch or delete, got #{word}" unless VERBS.key?(word)
      verb = VERBS[word]
      i = skip_space(text, i)
      raise ArgumentError, "#{where}: a route handler must be a { } block on one line" unless text[i] == "{"
      i = skip_space(text, i + 1)
      raise ArgumentError, "#{where}: a route block takes |app_context, request|" unless text[i] == "|"
      bar = text.index("|", i + 1)
      raise ArgumentError, "#{where}: a route block takes |app_context, request|" if bar.nil?
      params = text[i + 1, bar - i - 1].split(",").map { |name| name.strip }
      unless params.size == 2 && params.all? { |name| Template.identifier?(name) }
        raise ArgumentError, "#{where}: a route block takes two parameters, as |app_context, request|"
      end
      close = matching_brace(text, bar + 1, where)
      body = text[bar + 1, close - bar - 1].strip
      raise ArgumentError, "#{where}: an empty route block" if body.empty?
      after = skip_space(text, close + 1)
      raise ArgumentError, "#{where}: expected ) after the route block" unless text[after] == ")"
      full = group.prefix + (path == "/" ? "" : path)
      group.decls << Decl.new(verb, full.empty? ? "/" : full, owner, params, body, where)
      after + 1
    end

    # .add(local).add(Controller.routes)... after with_default_routes.
    def self.compose(rest, owner, where, scan)
      pos = rest.index(".add(")
      until pos.nil?
        close = rest.index(")", pos)
        raise ArgumentError, "#{where}: unclosed .add(" if close.nil?
        inner = rest[pos + 5, close - pos - 5].strip
        if Template.identifier?(inner)
          scan.composition << "#{owner}##{inner}"
        elsif inner.end_with?(".routes") && Template.identifier?(inner.delete_suffix(".routes").downcase)
          scan.composition << inner
        else
          raise ArgumentError, "#{where}: gen routes composes a local or Controller.routes, not #{inner}"
        end
        pos = rest.index(".add(", close)
      end
    end

    def self.string_at(text, pos, where)
      i = skip_space(text, pos)
      raise ArgumentError, "#{where}: expected a \"string\"" unless text[i] == "\""
      close = text.index("\"", i + 1)
      raise ArgumentError, "#{where}: unclosed string" if close.nil?
      text[i + 1, close - i - 1]
    end

    def self.skip_space(text, i)
      i += 1 while i < text.size && text[i] == " "
      i
    end

    # The } that closes the { before start, stepping over strings and
    # nested braces.
    def self.matching_brace(text, start, where)
      depth = 1
      i = start
      while i < text.size
        c = text[i]
        if c == "\"" || c == "'"
          i = TemplateCompile.after_string(text, i)
          next
        end
        depth += 1 if c == "{"
        depth -= 1 if c == "}"
        return i if depth == 0
        i += 1
      end
      raise ArgumentError, "#{where}: a route handler must be a { } block on one line"
    end

    # The routes in dispatch order: the framework defaults, then each
    # composed group in the order the app adds it.
    def self.ordered(scan)
      raise ArgumentError, "no Kilau::AppRoutes.with_default_routes under src/" if scan.hooks_class.empty?
      decls = []
      scan.composition.each do |key|
        group = scan.groups[key]
        raise ArgumentError, "#{scan.composition_where}: no routes found for #{key.tr("#", " ")}" if group.nil?
        group.decls.each { |decl| decls << decl }
      end
      decls
    end

    def self.render(scan)
      decls = ordered(scan)
      out = []
      out << "# GENERATED by `kilau gen routes` from src/. Do not edit; change the"
      out << "# routes and regenerate. Each handler body is copied from its route"
      out << "# block into a class method of the class that declared it, so self"
      out << "# is that class, and the dispatcher below calls it directly."
      owners = []
      decls.each { |decl| owners << decl.klass unless owners.include?(decl.klass) }
      owners.each do |owner|
        out << ""
        out << "class #{owner}"
        decls.each_with_index do |decl, i|
          next unless decl.klass == owner
          out << "  # #{decl.where}: #{decl.verb} #{decl.pattern}"
          out << "  def self.kilau_route_#{i + DEFAULTS.size}(#{decl.params.join(", ")})"
          out << "    #{decl.body}"
          out << "  end"
        end
        out << "end"
      end
      out << ""
      out << "module KilauRoutes"
      table = DEFAULTS.map { |d| "\"#{d[0]} #{d[1]}\"" } + decls.map { |decl| "\"#{decl.verb} #{decl.pattern}\"" }
      out << "  # What the app's route table holds, in order; a test compares the two."
      out << "  TABLE = [#{table.join(", ")}]"
      out << ""
      out << "  class Dispatcher"
      out << "    def initialize(app_context)"
      out << "      @app_context = app_context"
      out << "    end"
      out << ""
      out << "    def call(request)"
      out << "      Kilau::Dispatcher.apply_override(request)"
      out << "      app_context = @app_context"
      out << "      parts = request.path.split(\"/\")"
      out << "      parts.shift"
      out << "      case request.request_method"
      VERBS.values.each do |verb|
        calls = []
        DEFAULTS.each { |d| calls << [d[1], "#{d[2]}(app_context, request)"] if d[0] == verb }
        decls.each_with_index do |decl, i|
          calls << [decl.pattern, "#{decl.klass}.kilau_route_#{i + DEFAULTS.size}(app_context, request)"] if decl.verb == verb
        end
        next if calls.empty?
        out << "      when \"#{verb}\""
        calls.each do |pattern, call|
          segments = pattern.split("/").reject { |segment| segment.empty? }
          conds = [segments.empty? ? "parts.empty?" : "parts.size == #{segments.size}"]
          pairs = []
          segments.each_with_index do |segment, j|
            if segment.start_with?(":")
              conds << "!parts[#{j}].empty?"
              pairs << "\"#{segment[1, segment.size - 1]}\" => parts[#{j}]"
            else
              conds << "parts[#{j}] == #{segment.inspect}"
            end
          end
          out << "        if #{conds.join(" && ")}"
          out << "          request.path_params = #{pairs.empty? ? "{}" : "{ #{pairs.join(", ")} }"}"
          out << "          return #{call}"
          out << "        end"
        end
      end
      out << "      end"
      out << "      Kilau::Dispatcher.error_response(404, \"no route for \#{request.request_method} \#{request.path}\")"
      out << "    rescue Kilau::Error => e"
      out << "      Kilau::Dispatcher.error_response(e.status, e.message)"
      out << "    rescue StandardError => e"
      out << "      $stderr.puts \"kilau: \#{e.class}: \#{e.message}\""
      out << "      Kilau::Dispatcher.error_response(500, \"internal server error\")"
      out << "    end"
      out << "  end"
      out << "end"
      out << ""
      out << "# The app, served by the dispatcher above: bin/<app>_routes.rb runs"
      out << "# Kilau::CLI.run(Routed#{scan.hooks_class}.new, ...)."
      out << "class Routed#{scan.hooks_class} < #{scan.hooks_class}"
      out << "  def dispatcher(app_context) = KilauRoutes::Dispatcher.new(app_context)"
      out << "end"
      out.join("\n") + "\n"
    end
  end
end
