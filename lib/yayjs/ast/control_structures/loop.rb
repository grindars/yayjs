module YAYJS::AST::ControlStructures

  class Loop
    attr_reader :type, :on_break, :on_next, :on_redo, :loop_nodes

    def initialize(type, on_break, on_next, on_redo, loop_nodes)
      @type = type
      @on_break = on_break
      @on_next = on_next
      @on_redo = on_redo
      @loop_nodes = loop_nodes

      freeze
    end

    def self.identify(graph, head)
      postdoms       = graph.postdominators
      loops        = graph.identify_loops

      loop_nodes       = loops[head]

      possible_exit_points = postdoms[head].reject { |n| loop_nodes.include? n }
      exit_point       = Helpers.nearest_block head, possible_exit_points

      if !exit_point.nil?
        trampolines = Set.new(graph.sources_for(exit_point))
        trampolines.reject! do |node|
          node.instructions.length != 3 ||
          !node.instructions[0].kind_of?(YAYJS::Instructions::Putnil) ||
          !node.instructions[1].kind_of?(YAYJS::Instructions::MakeMutable) ||
          !node.instructions[2].kind_of?(YAYJS::Instructions::Jump)
        end

        trampolines.add exit_point
      else
        trampolines = nil
      end

      if !trampolines.nil? && Conditional.is_good_head(head)
        conditional = Conditional.identify graph, head

        if is_loop_conditional conditional, trampolines
          redo_target = if trampolines.include?(conditional.true_branch)
            conditional.false_branch
          else
            conditional.true_branch
          end

          return new :precondition, exit_point, head, redo_target, loop_nodes
        end
      end

      possible_heads = Set.new(graph.sources_for(head)) & loop_nodes
      possible_heads.reject! do |node|
        if Conditional.is_good_head(node)
          conditional = Conditional.identify graph, node

          !is_loop_conditional conditional, trampolines
        else
          true
        end
      end

      if possible_heads.length == 1
        return new :postcondition, exit_point, possible_heads.first, head, loop_nodes
      elsif possible_heads.length == 0
        return new :infinite, exit_point, head, head, loop_nodes
      end

      raise "Cannot identify #{head.label}'s loop type."
    end

    private

    def self.is_loop_conditional(conditional, trampolines)
       ( trampolines.include?(conditional.true_branch) && !trampolines.include?(conditional.false_branch)) ||
       (!trampolines.include?(conditional.true_branch) &&  trampolines.include?(conditional.false_branch))
    end
  end
end