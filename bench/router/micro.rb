# Fase D: linear matching (today's table dispatch: every route's match) against
# a segment trie, on synthetic route tables of 10, 100 and 1000 routes (5, 50
# and 500 indices). Each index i holds the pair `/r<i>/:id` and `/r<i>/:id/edit`; a lookup
# cycles over one request per index, so the average covers both shapes at
# every depth. The trie answers the same set of routes as the linear scan, and
# the run refuses to time a trie that disagrees.
#
#   ruby -I framework bench/router/micro.rb        (CRuby; the spinel build is bench/router/build.sh)
require "kilau"

module Micro
  LOOKUPS = 20_000

  # One node of a segment trie: literal children, one param child, and the
  # routes that end here. Children are typed by their use (a Hash of nodes,
  # one node for params), so no collection mixes kinds (K-015).
  class Node
    attr_reader :statics, :leaves
    attr_accessor :param

    def initialize
      @statics = {}
      @param = nil
      @leaves = []
    end
  end

  def self.insert(root, route)
    node = root
    Kilau::Route.split(route.pattern).each do |segment|
      if segment.start_with?(":")
        node.param = Node.new if node.param.nil?
        node = node.param
      else
        node.statics[segment] = Node.new unless node.statics.key?(segment)
        node = node.statics[segment]
      end
    end
    node.leaves << route
  end

  # Every route matching parts (the path split without its leading ""), out.
  def self.find(node, parts, i, out)
    if i == parts.size
      node.leaves.each { |route| out << route }
      return out
    end
    part = parts[i]
    child = node.statics[part]
    find(child, parts, i + 1, out) unless child.nil?
    find(node.param, parts, i + 1, out) if !node.param.nil? && !part.empty?
    out
  end

  def self.table(n)
    routes = []
    i = 0
    while i < n
      routes << Kilau::Route.new("GET", "/r#{i}/:id", Kilau::Controller.get { |c, r| r })
      routes << Kilau::Route.new("GET", "/r#{i}/:id/edit", Kilau::Controller.get { |c, r| r })
      i += 1
    end
    routes
  end

  def self.paths(n)
    out = []
    i = 0
    while i < n
      out << "/r#{i}/7"
      out << "/r#{i}/7/edit"
      i += 1
    end
    out
  end

  def self.linear(routes, path)
    hits = []
    routes.each { |route| hits << route unless route.match(path).nil? }
    hits
  end

  def self.run(n)
    routes = table(n)
    root = Node.new
    routes.each { |route| insert(root, route) }
    requests = paths(n)
    requests.each do |path|
      want = linear(routes, path).map { |route| route.pattern }.sort
      got = find(root, path.split("/").drop(1), 0, []).map { |route| route.pattern }.sort
      raise "trie and linear disagree on #{path}: #{want} vs #{got}" unless want == got
    end
    linear_ns = time(LOOKUPS) { |k| linear(routes, requests[k % requests.size]) }
    trie_ns = time(LOOKUPS) { |k| find(root, requests[k % requests.size].split("/").drop(1), 0, []) }
    [n, routes.size, linear_ns, trie_ns]
  end

  def self.time(count)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    k = 0
    while k < count
      yield k
      k += 1
    end
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    (elapsed * 1_000_000_000 / count).round
  end
end

if $PROGRAM_NAME == __FILE__
  puts "routes_in_table  linear_ns_per_lookup  trie_ns_per_lookup  speedup"
  [5, 50, 500].each do |n|
    _, count, linear_ns, trie_ns = Micro.run(n)
    speed = trie_ns == 0 ? 0 : (linear_ns.to_f / trie_ns).round(2)
    puts "#{count}  #{linear_ns}  #{trie_ns}  #{speed}"
  end
end
