module YAYJS::AST::ControlStructures

  class Conditional
    attr_reader :condition, :true_branch, :false_branch, :merge_point

    def initialize(condition, true_branch, false_branch, merge_point)
      @condition = condition
      @true_branch = true_branch
      @false_branch = false_branch
      @merge_point = merge_point

      freeze
    end


    def self.identify(graph, node)
      postdoms = graph.postdominators

      block_true, block_false = node.targets
      block_true, block_false = block_false, block_true if node.cti.kind_of? YAYJS::Instructions::Branchunless

      possible_merge_points = postdoms[block_true] & postdoms[block_false]

      merge_point     = Helpers.nearest_block block_true,  possible_merge_points
      check_merge_point = Helpers.nearest_block block_false, possible_merge_points

      if merge_point.nil? || check_merge_point.nil? || merge_point != check_merge_point
        raise "BUG: merge point of #{node.label} not found"
      end

      self.new node, block_true, block_false, merge_point
    end

    def self.is_good_head(node)
      node.cti.kind_of?(YAYJS::Instructions::Branchif) || node.cti.kind_of?(YAYJS::Instructions::Branchunless)
    end
  end
end