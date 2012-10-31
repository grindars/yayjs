module YAYJS::JSAST
  class VariableAssignmentNode < Furnace::AST::Node
    def initialize(variable, value)
      super :assign, [ variable, value ]
    end
  end
end