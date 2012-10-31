module YAYJS

  class CFGBuilder
    class AutonodeProducer
      def initialize(graph, prefix="autolabel")
        @graph = graph
        @prefix = prefix
        @index = 0
      end

      def next
        @index += 1

        Furnace::CFG::Node.new @graph, :"#{@prefix}_#{@index}"
      end
    end

    def initialize
      @iseq = nil
      @active_exceptions = nil
      @exception_nodes = nil
      @graph = nil
    end

    def build(iseq)
      @iseq = iseq
      @active_exceptions = []
      @exception_nodes = {}
      @graph = Furnace::CFG::Graph.new

      current_node = Furnace::CFG::Node.new @graph, :entry
      exit_node = Furnace::CFG::Node.new @graph, :exit

      @graph.nodes.add current_node
      @graph.nodes.add exit_node
      @graph.entry = current_node
      @graph.exit = exit_node

      @autonode = AutonodeProducer.new @graph

      iseq.bytecode.each do |instruction|
        case instruction
        when Instructions::Leave, Instructions::Finish
          current_node.instructions << instruction
          current_node.target_labels << :exit
          current_node.cti = instruction

          current_node = @autonode.next
          emit_exception_proxy current_node

          @graph.nodes.add current_node

        when Instructions::Jump
          current_node.instructions << instruction
          current_node.target_labels << instruction.dst
          current_node.cti = instruction

          current_node = @autonode.next
          emit_exception_proxy current_node
          @graph.nodes.add current_node

        when Instructions::Branchif, Instructions::Branchunless
          not_taken = @autonode.next

          current_node.instructions << instruction
          current_node.target_labels << instruction.dst << not_taken.label
          current_node.cti = instruction

          current_node = not_taken
          emit_exception_proxy current_node
          @graph.nodes.add current_node

        when Instructions::OptCaseDispatch
          current_node.instructions << instruction
          current_node.target_labels += instruction.target_hash.values
          current_node.target_labels << instruction.else_offset
          current_node.cti = instruction

          current_node = @autonode.next
          emit_exception_proxy current_node
          @graph.nodes.add current_node

        when Instructions::Label
          jump = Instructions::Jump.new instruction.location, [ instruction.label ]
          current_node.instructions << jump
          current_node.target_labels << instruction.label
          current_node.cti = jump

          current_node = Furnace::CFG::Node.new @graph, instruction.label

          iseq.exception_handlers.each do |exception|
            if exception.area_start == instruction.label
              @active_exceptions.unshift exception.cont
            end

            if exception.area_end == instruction.label
              @active_exceptions.delete exception.cont
            end
          end

          emit_exception_proxy current_node
          @graph.nodes.add current_node

        else
          current_node.instructions << instruction
        end
      end

      @exception_nodes.each do |area, node|
        receiver_infos = node.target_labels.map do |label|
          handler = iseq.exception_handlers.detect { |handler| handler.cont == label }

          { type: handler.type, sp: handler.sp, target: label }
        end

        prev_sp = 0

        receiver_infos.each do |info|
          next_node = @autonode.next
          @graph.nodes.add next_node

          if prev_sp > 0
            adjuststack = Instructions::Adjuststack.new Location::GENERATED, [ prev_sp ]
            node.instructions << adjuststack
          end

          prev_sp = info[:sp]
          dispatch = Instructions::ExceptionDispatch.new Location::GENERATED, [ info[:type], info[:sp], info[:target] ]
          node.instructions << dispatch
          node.target_labels = [ info[:target], next_node.label ]
          node.cti = dispatch

          node = next_node
        end

        if prev_sp > 0
          adjuststack = Instructions::Adjuststack.new Location::GENERATED, [ prev_sp ]
          node.instructions << adjuststack
        end

        rethrow = Instructions::ExceptionRethrow.new Location::GENERATED
        node.instructions << rethrow
      end

      @graph.eliminate_unreachable!
      @graph.merge_redundant!

      @graph
    end

    def emit_exception_proxy(node)
      used_exceptions = []
      used_types = Set[]

      @active_exceptions.each do |exception|
        exception_type = @iseq.exception_handlers.detect { |handler| handler.cont == exception }.type

        if !used_types.include? exception_type
          used_types.add exception_type
          used_exceptions << exception
        end
      end

      if used_exceptions.any?
        preexisting = @exception_nodes[@active_exceptions]

        if preexisting.nil?
          proxy_node = @autonode.next
          proxy_node.target_labels = used_exceptions
          proxy_node.metadata[:keep] = true

          @exception_nodes[@active_exceptions] = proxy_node
          @graph.nodes.add proxy_node

          node.exception_label = proxy_node.label
        else
          node.exception_label = preexisting.label
        end
      end
    end
  end
end
