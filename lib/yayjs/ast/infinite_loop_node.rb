module YAYJS::AST

  class InfiniteLoopNode < Furnace::AST::Node
    def initialize(body)
      super :infinite, [ body ]
    end
  end

end