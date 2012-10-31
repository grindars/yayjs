module YAYJS::JSAST
  class FunctionCallNode < Furnace::AST::Node
    def initialize(function, arglist)
      super :funcall, [ function, arglist ]
    end
  end
end