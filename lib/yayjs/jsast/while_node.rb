module YAYJS::JSAST
  class WhileNode < Furnace::AST::Node
    def initialize(condition, body)
      super :while, [ condition, body ]
    end
  end
end