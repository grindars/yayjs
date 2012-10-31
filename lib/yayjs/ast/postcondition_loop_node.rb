module YAYJS::AST

  class PostconditionLoopNode < Furnace::AST::Node
    def initialize(body, condition)
      super :postloop, [ body, condition ]
    end
  end

end