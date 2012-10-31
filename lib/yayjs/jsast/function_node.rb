module YAYJS::JSAST
  class FunctionNode < Furnace::AST::Node

    def initialize(args, body)
      super :function, [ args, body ]
    end
  end
end