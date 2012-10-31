module YAYJS
  class SSABuilder
    class SSAVariableIssuer
      def initialize
        @versions = Hash.new { 0 }
      end

      def issue(name)
        @versions[name] += 1

        :"#{name}.#{@versions[name]}"
      end
    end

    def convert(graph)
      @graph = graph
      @unconverted_nodes = graph.nodes.dup
      @issuer = SSAVariableIssuer.new
      @loops = @graph.identify_loops

      convert_node graph.entry

      if !@unconverted_nodes.empty? && (@unconverted_nodes.length > 1 || @unconverted_nodes.first != @graph.exit)
        lost = @unconverted_nodes.map &:label
        raise "Not all nodes converted. Lost nodes: #{lost.join ", "}"
      end

      @graph.nodes.each do |node|
        node.metadata.delete :ssa_stack
        node.metadata.delete :ssa_source_stack_depth
      end
    end

    def convert_node(node)
      raise "convert_node reentered for #{node.label}" if !@unconverted_nodes.include? node

      sources = Set.new @graph.sources_for(node)
      phi_required = sources.length >= 2
      loop_nodes = @loops[node]
      sources -= loop_nodes if !loop_nodes.nil?

      source_stack_depth = nil
      sources.each do |source|
        if @unconverted_nodes.include? source
          convert_node source

          return if !@unconverted_nodes.include? node
        end

        source_stack = source.metadata[:ssa_stack]
        if source_stack_depth.nil?
          source_stack_depth = source_stack.length
        elsif source_stack_depth != source_stack.length
          depths = sources.map do |stack_src|
            "#{stack_src.label} branched with #{stack_src.metadata[:ssa_stack].length} words in stack"
          end

          raise "Sources of #{node.label} have incompatible stacks: #{depths.join ", "}."
        end
      end

      source_stack_depth ||= 0

      stack = []
      node.metadata[:ssa_stack] = stack
      node.metadata[:ssa_source_stack_depth] = source_stack_depth

      if source_stack_depth != 0
        if phi_required
          (source_stack_depth - 1).downto(0) do |idx|
            map = {}

            sources.each do |source|
              source_stack = source.metadata[:ssa_stack]

              map[source.label] = source_stack[idx]
            end

            val = @issuer.issue(idx)
            stack.push val

            node.instructions.unshift PhiNode.new(map, val)
          end
        else
          sources.first.metadata[:ssa_stack].each { |var| stack << var }
        end
      end

      node.instructions.each_with_index do |instruction, index|
        next if instruction.kind_of? PhiNode

        raise "Stack underflow on #{instruction.inspect}. Stack contains: #{stack.join ", "}" if instruction.pops > stack.length

        args = stack.pop(instruction.pops).reverse!
        results = (0...instruction.pushes).map do |number|
          variable = @issuer.issue stack.length
          stack.push variable

          variable
        end

        results.reverse!

        ssa = SSAInstructionDecorator.new instruction, args, results
        node.instructions[index] = ssa
        ssa.freeze

        node.cti = ssa if node.cti == instruction
      end

      @unconverted_nodes.delete node

      node.targets.each do |dest_node|
        loop = @loops[dest_node]
        if !loop.nil? && loop.include?(self) && stack.length != dest_node.metadata[:ssa_source_stack_depth]
          raise "#{node.label} branched to #{dest_node.label} with incompatible stack. Expected: #{dest_node.metadata[:ssa_source_stack_depth]}, used: #{stack.length}"
        end

        convert_node dest_node if @unconverted_nodes.include? dest_node
      end
    end
  end
end
