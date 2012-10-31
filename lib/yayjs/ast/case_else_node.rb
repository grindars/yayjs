module YAYJS::AST

  class CaseElseNode < Furnace::AST::Node
    def initialize(block)
      super :case_else, [ block ]
    end
  end

end