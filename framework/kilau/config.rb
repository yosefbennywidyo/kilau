module Kilau
  # config/<env>.yaml read through a YAML subset (spec §3.1a): nested maps
  # of plain scalars. Values are read through typed getters by dotted path;
  # KILAU_<PATH> in the environment overrides the file. Spinel has no YAML
  # (docs/CATALOG.md K-002). Anything outside the subset is refused with
  # its line rather than read some other way.
  class Config
    class Error < StandardError
    end

    FORBIDDEN_VALUE_START = ["|", ">", "[", "{", "&", "*", "!", "'"]

    def self.load(path)
      raise Error, "config: no file at #{path}" unless File.exist?(path)
      parse(File.read(path), path)
    end

    def self.parse(text, source)
      values = {}
      quoted = {}
      maps = {}
      frame_paths = [""]
      frame_indents = [0]
      pending_path = ""
      pending_indent = -1
      pending_line = 0
      lineno = 0
      text.split("\n").each do |raw|
        lineno += 1
        where = "#{source}:#{lineno}"
        line = strip_comment(raw.end_with?("\r") ? raw[0, raw.size - 1] : raw)
        next if line.strip.empty?
        indent = line.size - line.lstrip.size
        raise Error, "#{where}: tabs are not allowed for indentation" if line[0, indent].include?("\t")

        if pending_indent >= 0
          raise Error, "#{source}:#{pending_line}: #{pending_path} has no value" if indent <= pending_indent
          frame_paths << pending_path
          frame_indents << indent
          pending_indent = -1
        else
          while frame_indents.size > 1 && frame_indents.last > indent
            frame_paths.pop
            frame_indents.pop
          end
          raise Error, "#{where}: indentation does not match any open map" if frame_indents.last != indent
        end

        body = line.strip
        raise Error, "#{where}: lists are not supported" if body == "-" || body.start_with?("- ")
        colon = body.index(":")
        raise Error, "#{where}: expected `key: value` or `key:`" if colon.nil? || colon == 0
        key = body[0, colon]
        raise Error, "#{where}: expected `key: value` or `key:`" unless key.match?(/\A[A-Za-z0-9_]+\z/)
        rest = body[colon + 1, body.size - colon - 1]
        raise Error, "#{where}: expected a space after `:`" unless rest.empty? || rest.start_with?(" ")
        rest = rest.strip
        full = frame_paths.last.empty? ? key : "#{frame_paths.last}.#{key}"
        raise Error, "#{where}: duplicate key #{full}" if values.key?(full) || maps.key?(full)

        if rest.empty?
          maps[full] = true
          pending_path = full
          pending_indent = indent
          pending_line = lineno
        elsif rest.start_with?("\"")
          inner = rest[1, rest.size - 1]
          close = inner.index("\"")
          if close.nil? || close != inner.size - 1
            raise Error, "#{where}: unterminated or embedded double quote"
          end
          values[full] = inner[0, inner.size - 1]
          quoted[full] = true
        else
          first = rest[0, 1]
          raise Error, "#{where}: values starting with #{first} are not supported" if FORBIDDEN_VALUE_START.include?(first)
          values[full] = rest
        end
      end
      raise Error, "#{source}:#{pending_line}: #{pending_path} has no value" if pending_indent >= 0
      new(values, quoted, source)
    end

    # A # starts a comment at the line start or after a space, outside
    # double quotes.
    def self.strip_comment(line)
      in_quote = false
      i = 0
      while i < line.size
        c = line[i]
        if c == "\""
          in_quote = !in_quote
        elsif c == "#" && !in_quote && (i == 0 || line[i - 1] == " ")
          return line[0, i].rstrip
        end
        i += 1
      end
      line.rstrip
    end

    def initialize(values, quoted, source)
      @values = values
      @quoted = quoted
      @source = source
    end

    def key?(path) = @values.key?(path)

    def string(path) = lookup(path)

    def int(path)
      value = lookup(path)
      if quoted_in_file?(path) || !value.match?(/\A-?\d{1,18}\z/)
        raise Error, "#{@source}: #{path} must be an integer, got #{value.inspect}"
      end
      value.to_i
    end

    def bool(path)
      value = lookup(path)
      return true if value == "true" && !quoted_in_file?(path)
      return false if value == "false" && !quoted_in_file?(path)
      raise Error, "#{@source}: #{path} must be true or false, got #{value.inspect}"
    end

    private

    def env_name(path) = "KILAU_" + path.upcase.tr(".", "_")

    def lookup(path)
      from_env = ENV[env_name(path)]
      return from_env unless from_env.nil?
      value = @values[path]
      raise Error, "#{@source}: missing key #{path}" if value.nil?
      value
    end

    def quoted_in_file?(path) = ENV[env_name(path)].nil? && @quoted.key?(path)
  end
end
