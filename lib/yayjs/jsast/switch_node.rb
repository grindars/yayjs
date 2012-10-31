module YAYJS::JSAST
  class SwitchNode < Furnace::AST::Node
    def initialize(expr, body)
      super :switch, [ expr, body ]
    end
  end
end