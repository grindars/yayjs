module YAYJS::JSAST
  class CatchNode < Furnace::AST::Node
    def initialize(variable, block)
      super :catch, [ variable, block ]
    end
  end
end