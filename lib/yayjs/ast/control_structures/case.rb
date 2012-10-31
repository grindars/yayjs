module YAYJS::AST::ControlStructures

  class Case
    attr_reader :head, :whens, :else_node, :merge_point

    def initialize(head, whens, else_node, merge_point)
      @head = head
      @whens = whens
      @else_node = else_node
      @merge_point = merge_point

      freeze
    end

    def self.identify(graph, node)
      postdoms = graph.postdominators

      possible_merge_points = nil
      node.targets.each_with_index do |target, index|
        if index == 0
          possible_merge_points = postdoms[target]
        else
          possible_merge_points &= postdoms[target]
        end
      end

      merge_point = nil
      node.targets.each_with_index do |target, index|
        check_merge_point = Helpers.nearest_block target, possible_merge_points

        if index == 0
          merge_point = check_merge_point
        end

        if merge_point.nil? || check_merge_point.nil? || merge_point != check_merge_point
          raise "BUG: merge point of #{node.label} not found"
        end
      end

      whens = {}

      node.cti.target_hash.each { |when_value, target_label| whens[when_value] = graph.find_node target_label }

      self.new node, whens, graph.find_node(node.cti.else_offset), merge_point
    end
  end
end