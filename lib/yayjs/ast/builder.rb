module YAYJS::AST
  class Builder
    class Context
      attr_accessor :conditional, :loop, :mode

      def initialize(conditional = nil, loop = nil, mode = nil)
        @conditional = conditional
        @loop = loop
        @mode = mode
      end
    end

    def initialize
      @graph = nil
      @postdoms = nil
      @loops = nil
      @nesting = 0
    end

    def build(graph, iseq)
      @graph = graph
      @postdoms = @graph.postdominators
      @loops = @graph.identify_loops

      ISeqNode.new iseq, wrap_node(graph.entry)
    end

    private

    def wrap_node(node, context = Context.new)
      @nesting += 1

      begin
        if !context.loop.nil?
          case node
          when context.loop.on_break
            return BlockNode.new [ BreakNode.new ]

          when context.loop.on_next
            return BlockNode.new [ NextNode.new ]

          when context.loop.on_redo
            if context.mode == :loop_condition
              return BlockNode.new
            else
              return BlockNode.new [ RedoNode.new ]
            end
          end
        end

        node_loop = @loops[node]

        if node_loop.nil?
          BlockNode.new wrap_block_contents(node, context)
        else
          new_loop = ControlStructures::Loop.identify @graph, node
          contents = []

          if new_loop.on_next == new_loop.on_redo
            condition_contents = []
          else
            condition_contents = wrap_block_contents new_loop.on_next, Context.new(nil, new_loop, :loop_condition)
          end

          body_contents = wrap_block_contents new_loop.on_redo, Context.new(nil, new_loop, nil)

          loop_node = case new_loop.type
          when :precondition
            condition_contents =
            PreconditionLoopNode.new(
              BlockNode.new(condition_contents),
              BlockNode.new(body_contents)
            )

          when :postcondition
            PostconditionLoopNode.new(
              BlockNode.new(body_contents),
              BlockNode.new(condition_contents)
            )

          when :infinite
            InfiniteLoopNode.new BlockNode.new(body_contents)
          end

          if new_loop.on_break.nil?
            loop_node
          else
            rest_contents = wrap_block_contents new_loop.on_break, context
            rest_contents.unshift loop_node

            BlockNode.new rest_contents
          end
        end
      ensure
        @nesting -= 1
      end
    end

    def wrap_block_contents(node, context)
      block_contents = []

      node.instructions.each do |instruction|
        argument_nodes = instruction.args.map { |var| SSAFetchNode.new var }
        instruction_node = nil

        if instruction == node.cti
          case instruction.instruction
          when YAYJS::Instructions::Branchif, YAYJS::Instructions::Branchunless
            new_conditional = ControlStructures::Conditional.identify @graph, node
            new_context = Context.new new_conditional, context.loop, context.mode

            if_node = IfNode.new argument_nodes[0],
                       wrap_node(new_conditional.true_branch, new_context),
                       wrap_node(new_conditional.false_branch, new_context)

            if !context.loop.nil? &&
              context.mode == :loop_condition &&
              new_conditional.merge_point == context.loop.on_break

              instruction_node = if_node
            else
              instruction_node = BlockNode.new [
                if_node,
                wrap_node(new_conditional.merge_point, context)
              ]
            end

          when YAYJS::Instructions::Jump
            if (context.conditional.nil? || node.targets[0] != context.conditional.merge_point)
              instruction_node = wrap_node node.targets[0], context
            end

          when YAYJS::Instructions::Leave
            instruction_node = LeaveNode.new argument_nodes[0]

          when YAYJS::Instructions::OptCaseDispatch
            new_conditional = ControlStructures::Case.identify @graph, node
            new_context = Context.new new_conditional, context.loop, context.mode

            whens = new_conditional.whens.map { |v, n| CaseWhenNode.new v, wrap_node(n, new_context) }
            whens.unshift argument_nodes[0]
            whens.push CaseElseNode.new(wrap_node(new_conditional.else_node, new_context))

            instruction_node = BlockNode.new [
              CaseNode.new(whens),
              wrap_node(new_conditional.merge_point, context)
            ]

          else
            raise "Unimplemented CTI: #{instruction.inspect}"
          end
        elsif instruction.kind_of? YAYJS::PhiNode
          raise "Phi node found during AST building: #{instruction.inspect}"
        else
          instruction_node = GenericInstructionNode.new instruction, argument_nodes.reverse

          if instruction.results.length == 1
            instruction_node = SSAStoreNode.new instruction.results[0], instruction_node
          elsif instruction.results.length >= 2
            instruction_node = SSAStoreMultipleNode.new instruction.results, instruction_node
          end
        end

        block_contents << instruction_node unless instruction_node.nil?
      end

      block_contents
    end
  end
end
