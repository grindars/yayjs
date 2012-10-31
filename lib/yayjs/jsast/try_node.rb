module YAYJS::JSAST
  class TryNode < Furnace::AST::Node
    def initialize(children)
      super :try, children
    end
  end
end