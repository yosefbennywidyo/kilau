require_relative "template_lexer"

module KilauTool
  # One parsed template: its path under assets/views, the Templates method
  # it compiles to, its declared args, and its tokens.
  class Template
    attr_reader :path, :method_name, :args, :tokens

    ARGS_OPEN = "{#- args:"
    ARGS_CLOSE = "-#}"
    KEYWORDS = %w[nil true false self and or not if elsif unless then else end do while until
                  case when in for begin rescue ensure return yield def class module super
                  defined? alias undef redo retry break next BEGIN END]

    def initialize(path, method_name, args, tokens)
      @path = path
      @method_name = method_name
      @args = args
      @tokens = tokens
    end

    # path: relative to assets/views ("posts/show.html").
    def self.parse(path, source)
      newline = source.index("\n")
      header = (newline.nil? ? source : source[0, newline]).strip
      body = newline.nil? ? "" : source[newline + 1, source.size - newline - 1]
      unless header.start_with?(ARGS_OPEN) && header.end_with?(ARGS_CLOSE)
        raise ArgumentError, "#{path}:1: the first line must be {#- args: a, b -#}"
      end
      list = header[ARGS_OPEN.size, header.size - ARGS_OPEN.size - ARGS_CLOSE.size].strip
      args = list.split(",").map { |arg| arg.strip }
      args.each_with_index do |arg, i|
        check_name(arg, path, 1)
        raise ArgumentError, "#{path}:1: argument #{arg} is declared twice" if args.index(arg) != i
      end
      new(path, method_name_for(path), args, TemplateLexer.tokenize(body, path, 2))
    end

    # posts/_form.html -> posts__form
    def self.method_name_for(path)
      raise ArgumentError, "#{path}: a template file must end in .html" unless path.end_with?(".html")
      name = path[0, path.size - 5].tr("/", "_")
      raise ArgumentError, "#{path}: #{name} is not a valid Ruby method name" unless identifier?(name)
      name
    end

    # A local the generated method will hold: an arg or a loop variable.
    # buf and block_* are the generated code's own locals.
    def self.check_name(name, path, line)
      unless identifier?(name) && !KEYWORDS.include?(name)
        raise ArgumentError, "#{path}:#{line}: #{name.inspect} is not a valid variable name"
      end
      if name == "buf" || name.start_with?("block_")
        raise ArgumentError, "#{path}:#{line}: #{name} is reserved by the generated code"
      end
    end

    def self.identifier?(name)
      return false if name.empty? || !lower_start?(name[0])
      i = 1
      while i < name.size
        return false unless word_char?(name[i])
        i += 1
      end
      true
    end

    def self.lower_start?(c) = (c >= "a" && c <= "z") || c == "_"
    def self.word_char?(c) = (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9") || c == "_"
  end
end
