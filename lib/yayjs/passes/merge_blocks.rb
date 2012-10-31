module YAYJS::Passes
  class MergeBlocks < ASTPass
    def process_blocknode(node)
      YAYJS::AST::BlockNode.new collect_block_contents(node)
    end

    def collect_block_contents(node)
      contents = []

      node.children.each do |child_node|
        if child_node.kind_of? YAYJS::AST::BlockNode
          contents += collect_block_contents child_node
        else
          contents << process(child_node)
        end
      end

      contents
    end

  end
end

