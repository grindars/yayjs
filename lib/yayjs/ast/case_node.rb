module YAYJS::AST

  class CaseNode < Furnace::AST::Node
    def initialize(children)
      super :case, children
    end
  end

end