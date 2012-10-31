module YAYJS::AST

  class BreakNode < Furnace::AST::Node
    def initialize
      super :break
    end
  end

end