# Fase D, generate mode: the same synthetic tables as micro.rb, dispatched the
# way `kilau gen routes` emits them: one `if` per route, in table order, the
# first match returns. Emits one standalone file per index count, which
# includes micro.rb's module (linear, trie) and times all three matchers.
#
#   ruby bench/router/gen_micro.rb OUT_DIR
require_relative "micro"

module GenMicro
  # The chain for n indices: returns the route's position in the table, or -1.
  def self.chain_source(n)
    lines = []
    lines << "  def self.gen_match(parts)"
    i = 0
    pos = 0
    while i < n
      lines << "    return #{pos} if parts.size == 2 && parts[0] == \"r#{i}\" && !parts[1].empty?"
      pos += 1
      lines << "    return #{pos} if parts.size == 3 && parts[0] == \"r#{i}\" && !parts[1].empty? && parts[2] == \"edit\""
      pos += 1
      i += 1
    end
    lines << "    -1"
    lines << "  end"
    lines.join("\n")
  end

  # The hybrid: a case on the first segment, then the if chain of only the
  # routes that start with it (what a dispatcher that switches on the first
  # segment and chains the rest would emit). Positions match chain_source's.
  def self.hybrid_source(n)
    lines = []
    lines << "  def self.hybrid_match(parts)"
    lines << "    case parts[0]"
    i = 0
    while i < n
      pos = 2 * i
      lines << "    when \"r#{i}\""
      lines << "      return #{pos} if parts.size == 2 && !parts[1].empty?"
      lines << "      return #{pos + 1} if parts.size == 3 && !parts[1].empty? && parts[2] == \"edit\""
      lines << "      return -1"
      i += 1
    end
    lines << "    else"
    lines << "      -1"
    lines << "    end"
    lines << "  end"
    lines.join("\n")
  end

  def self.emit(n, out_dir)
    base = File.read(File.join(__dir__, "micro.rb"))
    head = base[0...base.index("if $PROGRAM_NAME == __FILE__")]
    main = <<~RUBY
      if $PROGRAM_NAME == __FILE__
        n = #{n}
        routes = Micro.table(n)
        root = Micro::Node.new
        routes.each { |route| Micro.insert(root, route) }
        requests = Micro.paths(n)
        requests.each_with_index do |path, k|
          first = Micro.linear(routes, path).first
          want = routes.index(first)
          raise "gen chain disagrees on \#{path}" unless GenMicro.gen_match(path.split("/").drop(1)) == want
          raise "hybrid disagrees on \#{path}" unless GenMicro.hybrid_match(path.split("/").drop(1)) == want
        end
        linear_ns = Micro.time(Micro::LOOKUPS) { |k| Micro.linear(routes, requests[k % requests.size]) }
        trie_ns = Micro.time(Micro::LOOKUPS) { |k| Micro.find(root, requests[k % requests.size].split("/").drop(1), 0, []) }
        gen_ns = Micro.time(Micro::LOOKUPS) { |k| GenMicro.gen_match(requests[k % requests.size].split("/").drop(1)) }
        hybrid_ns = Micro.time(Micro::LOOKUPS) { |k| GenMicro.hybrid_match(requests[k % requests.size].split("/").drop(1)) }
        puts "routes=\#{routes.size} linear=\#{linear_ns} trie=\#{trie_ns} gen=\#{gen_ns} hybrid=\#{hybrid_ns}"
      end
    RUBY
    body = head + "\nmodule GenMicro\n" + chain_source(n) + "\n" + hybrid_source(n) + "\nend\n" + main
    path = File.join(out_dir, "micro_gen_#{n}.rb")
    File.write(path, body)
    path
  end
end

if $PROGRAM_NAME == __FILE__
  out_dir = ARGV.fetch(0)
  # index counts: 2 routes per index, so 300, 600 and 750 routes
  [150, 300, 375].each { |n| puts GenMicro.emit(n, out_dir) }
end
