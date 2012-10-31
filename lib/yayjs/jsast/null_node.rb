module YAYJS::JSAST
  class NullNode < Furnace::AST::Node
    def initialize
      super :null
    end
  end
end