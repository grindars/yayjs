module YAYJS::Passes
  class MergePhiNodes < CFGPass
    def process(graph)
      super

      autonode = YAYJS::CFGBuilder::AutonodeProducer.new @graph, "phiexpand"

      new_nodes = []

      @graph.nodes.each do |node|
        phi_nodes = []

        node.instructions.reject! do |insn|
          if insn.kind_of? YAYJS::PhiNode
            phi_nodes << insn

            true
          else
            break
          end
        end

        next unless phi_nodes.any?

        new_nodes += @graph.sources_for(node).map do |src_node|
          proxy_node = autonode.next

          src_node.target_labels.each_with_index do |label, index|
            src_node.target_labels[index] = proxy_node.label if label == node.label
          end

          if src_node.cti.dst == node.label
            new_cti = YAYJS::SSAInstructionDecorator.new src_node.cti.instruction.class.new(src_node.cti.location, [ proxy_node.label ]),
                                    src_node.cti.args, src_node.cti.results

            src_node.cti = new_cti
            src_node.instructions.pop
            src_node.instructions.push  new_cti
          end

          phi_nodes.each do |phi_node|
            copy = YAYJS::SSAInstructionDecorator.new YAYJS::Instructions::MakeMutable.new(YAYJS::Location::GENERATED),
                                   [ phi_node.map[src_node.label] ], phi_node.results

            proxy_node.instructions << copy
          end

          jump = YAYJS::SSAInstructionDecorator.new(YAYJS::Instructions::Jump.new(YAYJS::Location::GENERATED, [ node.label ]),
                                 [], [])
          proxy_node.instructions << jump
          proxy_node.cti = jump
          proxy_node.target_labels << node.label

          proxy_node
        end
      end

      new_nodes.each { |node| @graph.nodes.add node }

      @graph.flush
    end
  end
end
