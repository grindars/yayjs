module YAYJS::JSAST
  class IfNode < Furnace::AST::Node
    def initialize(condition, true_branch, false_branch)
      super :if, [ condition, true_branch, false_branch ]
    end
  end
end