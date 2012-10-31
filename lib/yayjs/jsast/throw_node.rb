module YAYJS::JSAST
  class ThrowNode < Furnace::AST::Node
    def initialize(value)
      super :throw, [ value ]
    end
  end
end