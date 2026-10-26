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
        # A commented-out route must stay out, even after live code.
        text = strip_comment(line).strip
        indent = line.size - line.lstrip.size
        if text.start_with?("class ")
          name = text[6, text.size - 6].split(" ")[0].to_s
          klass = indent == 0 ? name : ""
        elsif indent == 0 && (text.start_with?("module ") || text == "end")
          # Leaving a top-level class, or entering a module: no class owns
          # what follows, so routes there are refused rather than given to
          # the last class seen.
          klass = ""
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
      # A heredoc's text is on the following lines, which the copy would
      # leave behind, so the generated file would not parse.
      raise ArgumentError, "#{where}: a route block cannot open a heredoc" if heredoc?(body)
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

    # The line without a trailing # comment; a # inside a string literal
    # stays.
    def self.strip_comment(line)
      i = 0
      while i < line.size
        c = line[i]
        if c == "\"" || c == "'"
          i = TemplateCompile.after_string(line, i)
        elsif c == "#"
          return line[0, i]
        else
          i += 1
        end
      end
      line
    end

    HEREDOC_MARKS = ["~", "-", "\"", "'", "`"]

    def self.heredoc?(body)
      at = body.index("<<")
      until at.nil?
        mark = body[at + 2].to_s
        return true if HEREDOC_MARKS.include?(mark) || (mark >= "A" && mark <= "Z")
        at = body.index("<<", at + 2)
      end
      false
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

    # Two routes share a shape when they have the same literal at every static
    # position, whatever their param names; specificity is a bitmask with the
    # leftmost segment as the most significant bit, set where a segment is a
    # param, so a lower value is more static (Fase C, same as Kilau::Route).
    def self.shape_key(pattern)
      pattern.split("/").reject { |segment| segment.empty? }.map { |segment| segment.start_with?(":") ? "\0" : segment }.join("/")
    end

    def self.specificity(pattern)
      segments = pattern.split("/").reject { |segment| segment.empty? }
      value = 0
      i = 0
      while i < segments.size
        value |= (1 << (segments.size - 1 - i)) if segments[i].start_with?(":")
        i += 1
      end
      value
    end

    # The routes in dispatch order: the framework defaults, then each
    # composed group in the order the app adds it. Two routes with the same
    # verb and shape are refused here, with both declarations' lines (Fase C).
    def self.ordered(scan)
      raise ArgumentError, "no Kilau::AppRoutes.with_default_routes under src/" if scan.hooks_class.empty?
      decls = []
      scan.composition.each do |key|
        group = scan.groups[key]
        raise ArgumentError, "#{scan.composition_where}: no routes found for #{key.tr("#", " ")}" if group.nil?
        group.decls.each { |decl| decls << decl }
      end
      seen = []
      DEFAULTS.each { |d| seen << [d[0], shape_key(d[1]), "<kilau defaults>", d[1]] }
      decls.each { |decl| seen << [decl.verb, shape_key(decl.pattern), decl.where, decl.pattern] }
      i = 0
      while i < seen.size
        j = 0
        while j < i
          if seen[j][0] == seen[i][0] && seen[j][1] == seen[i][1]
            raise ArgumentError, "#{seen[i][2]}: duplicate route #{seen[i][0]} #{seen[i][3]} conflicts with #{seen[j][2]}: #{seen[j][0]} #{seen[j][3]} (same shape)"
          end
          j += 1
        end
        i += 1
      end
      decls
    end

    # The per-segment conditions and path_params pairs for one route's
    # pattern, shared between the dispatch arm and its Allow bookkeeping.
    def self.route_conditions(pattern)
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
      [conds, pairs]
    end

    # The first segment of a pattern when it is a literal, or "" when it is a
    # param or the pattern has no segments.
    def self.first_literal(pattern)
      segment = pattern.split("/").reject { |part| part.empty? }[0]
      segment.nil? || segment.start_with?(":") ? "" : segment
    end

    # Any pattern of group g (the groups share one shape, so their first
    # segment is the same literal or param).
    def self.group_pattern(all_routes, route_group, g)
      r = 0
      r += 1 while r < route_group.size && route_group[r] != g
      all_routes[r][1]
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
      out << "      verb = request.request_method"
      out << "      match_verb = verb == \"HEAD\" ? \"GET\" : verb"
      # Every route, in table order: its verb, its call, its per-route path_params
      # pairs, and the shape group it belongs to. Parallel arrays of one element
      # type each (no Array mixes types).
      all_routes = DEFAULTS.map { |d| [d[0], d[1], "#{d[2]}(app_context, request)"] } +
        decls.each_with_index.map { |decl, i| [decl.verb, decl.pattern, "#{decl.klass}.kilau_route_#{i + DEFAULTS.size}(app_context, request)"] }
      group_keys = []
      group_specs = []
      group_conds = []
      route_group = []
      route_verbs = []
      route_calls = []
      route_pairs = []
      all_routes.each do |verb, pattern, call|
        key = shape_key(pattern)
        gi = -1
        group_keys.each_with_index { |k, g| gi = g if gi < 0 && k == key }
        if gi < 0
          gi = group_keys.size
          conds, _pairs = route_conditions(pattern)
          group_keys << key
          group_specs << specificity(pattern)
          group_conds << conds.join(" && ")
        end
        route_group << gi
        route_verbs << verb
        route_calls << call
        _conds, pairs = route_conditions(pattern)
        route_pairs << (pairs.empty? ? "{}" : "{ #{pairs.join(", ")} }")
      end
      # Groups in ascending specificity (insertion sort, no sort_by): the first
      # group whose conditions match is the winner, and every branch returns.
      order = []
      group_keys.each_with_index { |_k, g| order << g }
      i = 1
      while i < order.size
        j = i
        while j > 0 && group_specs[order[j - 1]] > group_specs[order[j]]
          tmp = order[j - 1]
          order[j - 1] = order[j]
          order[j] = tmp
          j -= 1
        end
        i += 1
      end
      # The groups whose first segment is a literal are switched on it (a case
      # with one when per segment, as the measured hybrid in bench/ROUTER.md); a
      # group inside a when keeps its specificity order. The rest, whose first
      # segment is a param or absent, follow the switch in their own order: a
      # literal first segment always outranks a param one at the same length.
      group_first = []
      group_keys.each_with_index { |_k, g| group_first << first_literal(group_pattern(all_routes, route_group, g)) }
      buckets = []
      order.each { |g| buckets << group_first[g] unless group_first[g].empty? || buckets.include?(group_first[g]) }
      emit = lambda do |g, pad|
        out << "#{pad}if #{group_conds[g]}"
        members = []
        route_group.each_with_index { |rg, r| members << r if rg == g }
        verbs = members.map { |r| "\"#{route_verbs[r]}\"" }
        out << "#{pad}  allowed = [#{verbs.join(", ")}]"
        out << "#{pad}  case match_verb"
        members.each do |r|
          out << "#{pad}  when \"#{route_verbs[r]}\""
          out << "#{pad}    request.path_params = #{route_pairs[r]}"
          out << "#{pad}    response = #{route_calls[r]}"
          out << "#{pad}    return verb == \"HEAD\" ? response.without_body : response"
        end
        out << "#{pad}  else"
        out << "#{pad}    allowed << \"HEAD\" if allowed.include?(\"GET\") && !allowed.include?(\"HEAD\")"
        out << "#{pad}    allowed = allowed.uniq.sort"
        out << "#{pad}    return Kilau::Dispatcher.options_response(allowed) if verb == \"OPTIONS\""
        out << "#{pad}    response = Kilau::Dispatcher.method_not_allowed(allowed, verb, request.path)"
        out << "#{pad}    return verb == \"HEAD\" ? response.without_body : response"
        out << "#{pad}  end"
        out << "#{pad}end"
      end
      unless buckets.empty?
        out << "      case parts[0]"
        buckets.each do |f|
          out << "      when #{f.inspect}"
          order.each { |g| emit.call(g, "        ") if group_first[g] == f }
        end
        out << "      end"
      end
      order.each { |g| emit.call(g, "      ") if group_first[g].empty? }
      out << "      response = Kilau::Dispatcher.error_response(404, \"no route for \#{verb} \#{request.path}\")"
      out << "      verb == \"HEAD\" ? response.without_body : response"
      out << "    rescue Kilau::Error => e"
      out << "      response = Kilau::Dispatcher.error_response(e.status, e.message)"
      out << "      request.request_method == \"HEAD\" ? response.without_body : response"
      out << "    rescue StandardError => e"
      out << "      $stderr.puts \"kilau: \#{e.class}: \#{e.message}\""
      out << "      response = Kilau::Dispatcher.error_response(500, \"internal server error\")"
      out << "      request.request_method == \"HEAD\" ? response.without_body : response"
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
