module YAYJS::AST

  class BlockNode < Furnace::AST::Node

    def initialize(children = [])
      super :block, children
    end
  end

end