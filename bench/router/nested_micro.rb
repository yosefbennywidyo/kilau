# Fase D, trie bersarang: tables with two static levels, so a case can switch on
# each. Five first segments (s0..s4), B second segments (t0..t<B-1>) under each,
# and per (i, j) two routes: /s<i>/t<j>/:id and /s<i>/t<j>/:id/edit. A table of R
# routes has B = R / 10. Four matchers, all checked against the linear scan:
#   trie    Micro.find over the runtime trie (micro.rb)
#   if      one `if` per route, in table order (gen mode today)
#   case+if case on the first segment, `if` chain inside (D-027)
#   nested  case on the first segment, case on the second, `if` at the leaf
#
#   ruby bench/router/nested_micro.rb OUT_DIR [ROUTES...]
require_relative "micro"

module NestedMicro
  FIRST = 5

  def self.table(b)
    routes = []
    i = 0
    while i < FIRST
      j = 0
      while j < b
        routes << Kilau::Route.new("GET", "/s#{i}/t#{j}/:id", Kilau::Controller.get { |c, r| r })
        routes << Kilau::Route.new("GET", "/s#{i}/t#{j}/:id/edit", Kilau::Controller.get { |c, r| r })
        j += 1
      end
      i += 1
    end
    routes
  end

  def self.paths(b)
    out = []
    i = 0
    while i < FIRST
      j = 0
      while j < b
        out << "/s#{i}/t#{j}/7"
        out << "/s#{i}/t#{j}/7/edit"
        j += 1
      end
      i += 1
    end
    out
  end

  # The positions in table order: the pair for (i, j) is at 2 * (i * b + j).
  def self.if_source(b)
    lines = ["  def self.if_match(parts)"]
    i = 0
    while i < FIRST
      j = 0
      while j < b
        pos = 2 * (i * b + j)
        lines << "    return #{pos} if parts.size == 3 && parts[0] == \"s#{i}\" && parts[1] == \"t#{j}\" && !parts[2].empty?"
        lines << "    return #{pos + 1} if parts.size == 4 && parts[0] == \"s#{i}\" && parts[1] == \"t#{j}\" && !parts[2].empty? && parts[3] == \"edit\""
        j += 1
      end
      i += 1
    end
    lines << "    -1"
    lines << "  end"
    lines.join("\n")
  end

  def self.case_if_source(b)
    lines = ["  def self.case_if_match(parts)", "    case parts[0]"]
    i = 0
    while i < FIRST
      lines << "    when \"s#{i}\""
      j = 0
      while j < b
        pos = 2 * (i * b + j)
        lines << "      return #{pos} if parts.size == 3 && parts[1] == \"t#{j}\" && !parts[2].empty?"
        lines << "      return #{pos + 1} if parts.size == 4 && parts[1] == \"t#{j}\" && !parts[2].empty? && parts[3] == \"edit\""
        j += 1
      end
      lines << "      return -1"
      i += 1
    end
    lines << "    else"
    lines << "      -1"
    lines << "    end"
    lines << "  end"
    lines.join("\n")
  end

  def self.nested_source(b)
    lines = ["  def self.nested_match(parts)", "    case parts[0]"]
    i = 0
    while i < FIRST
      lines << "    when \"s#{i}\""
      lines << "      case parts[1]"
      j = 0
      while j < b
        pos = 2 * (i * b + j)
        lines << "      when \"t#{j}\""
        lines << "        return #{pos} if parts.size == 3 && !parts[2].empty?"
        lines << "        return #{pos + 1} if parts.size == 4 && !parts[2].empty? && parts[3] == \"edit\""
        lines << "        return -1"
        j += 1
      end
      lines << "      else"
      lines << "        return -1"
      lines << "      end"
      i += 1
    end
    lines << "    else"
    lines << "      -1"
    lines << "    end"
    lines << "  end"
    lines.join("\n")
  end

  def self.emit(routes_count, out_dir)
    b = routes_count / (2 * FIRST)
    base = File.read(File.join(__dir__, "micro.rb"))
    head = base[0...base.index("if $PROGRAM_NAME == __FILE__")]
    main = <<~RUBY
      if $PROGRAM_NAME == __FILE__
        b = #{b}
        routes = NestedMicro.table(b)
        root = Micro::Node.new
        routes.each { |route| Micro.insert(root, route) }
        requests = NestedMicro.paths(b)
        requests.each do |path|
          parts = path.split("/").drop(1)
          want = routes.index(Micro.linear(routes, path).first)
          raise "if disagrees on \#{path}" unless NestedMicro.if_match(parts) == want
          raise "case+if disagrees on \#{path}" unless NestedMicro.case_if_match(parts) == want
          raise "nested disagrees on \#{path}" unless NestedMicro.nested_match(parts) == want
          raise "trie disagrees on \#{path}" unless Micro.find(root, parts, 0, []).map { |r| routes.index(r) }.sort == Micro.linear(routes, path).map { |r| routes.index(r) }.sort
        end
        linear_ns = Micro.time(Micro::LOOKUPS) { |k| Micro.linear(routes, requests[k % requests.size]) }
        trie_ns = Micro.time(Micro::LOOKUPS) { |k| Micro.find(root, requests[k % requests.size].split("/").drop(1), 0, []) }
        if_ns = Micro.time(Micro::LOOKUPS) { |k| NestedMicro.if_match(requests[k % requests.size].split("/").drop(1)) }
        case_if_ns = Micro.time(Micro::LOOKUPS) { |k| NestedMicro.case_if_match(requests[k % requests.size].split("/").drop(1)) }
        nested_ns = Micro.time(Micro::LOOKUPS) { |k| NestedMicro.nested_match(requests[k % requests.size].split("/").drop(1)) }
        puts "routes=\#{routes.size} linear=\#{linear_ns} trie=\#{trie_ns} if=\#{if_ns} case_if=\#{case_if_ns} nested=\#{nested_ns}"
      end
    RUBY
    table_src = <<~RUBY
      module NestedMicro
        FIRST = 5
        def self.table(b)
          routes = []
          i = 0
          while i < FIRST
            j = 0
            while j < b
              routes << Kilau::Route.new("GET", "/s\#{i}/t\#{j}/:id", Kilau::Controller.get { |c, r| r })
              routes << Kilau::Route.new("GET", "/s\#{i}/t\#{j}/:id/edit", Kilau::Controller.get { |c, r| r })
              j += 1
            end
            i += 1
          end
          routes
        end
        def self.paths(b)
          out = []
          i = 0
          while i < FIRST
            j = 0
            while j < b
              out << "/s\#{i}/t\#{j}/7"
              out << "/s\#{i}/t\#{j}/7/edit"
              j += 1
            end
            i += 1
          end
          out
        end
      end
    RUBY
    body = head + "\n" + table_src + "\nmodule NestedMicro\n" + if_source(b) + "\n" + case_if_source(b) + "\n" + nested_source(b) + "\nend\n" + main
    path = File.join(out_dir, "nested_#{routes_count}.rb")
    File.write(path, body)
    path
  end
end

if $PROGRAM_NAME == __FILE__
  out_dir = ARGV.fetch(0)
  counts = ARGV.size > 1 ? ARGV[1..].map(&:to_i) : [10, 100, 300, 600, 750]
  counts.each { |c| puts NestedMicro.emit(c, out_dir) }
end
