module YAYJS::JSAST
  class ArraySubscriptNode < Furnace::AST::Node
    def initialize(array, subscript)
      super :subscript, [ array, subscript ]
    end
  end
end