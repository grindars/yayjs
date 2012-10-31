module YAYJS::AST

  class PreconditionLoopNode < Furnace::AST::Node
    def initialize(condition, body)
      super :preloop, [ condition, body ]
    end
  end

end