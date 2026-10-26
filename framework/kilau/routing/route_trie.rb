module Kilau
  # The routes of an app as a segment trie (Fase D): a request walks one node
  # per path segment instead of testing every route. A node has literal
  # children, one param child, and the indices of the routes that end there.
  # matches answers the same routes Route#match accepts, as indices into the
  # table the trie was built from. Built once at boot.
  class RouteTrie
    class Node
      attr_reader :statics, :leaves
      attr_accessor :param

      def initialize
        @statics = {}
        @param = nil
        @leaves = []
      end
    end

    def self.build(routes)
      trie = RouteTrie.new
      routes.each_with_index { |route, i| trie.insert(route, i) }
      trie
    end

    def initialize
      @root = Node.new
    end

    def insert(route, index)
      node = @root
      Route.split(route.pattern).each do |segment|
        if segment.start_with?(":")
          node.param = Node.new if node.param.nil?
          node = node.param
        else
          node.statics[segment] = Node.new unless node.statics.key?(segment)
          node = node.statics[segment]
        end
      end
      node.leaves << index
    end

    # The indices of every route matching path, in no particular order.
    def matches(path)
      parts = path.split("/")
      parts.shift
      found = []
      collect(@root, parts, 0, found)
      found
    end

    def collect(node, parts, i, found)
      if i == parts.size
        node.leaves.each { |index| found << index }
        return found
      end
      part = parts[i]
      child = node.statics[part]
      collect(child, parts, i + 1, found) unless child.nil?
      collect(node.param, parts, i + 1, found) if !node.param.nil? && !part.empty?
      found
    end
  end
end
