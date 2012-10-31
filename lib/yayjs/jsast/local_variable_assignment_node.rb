module YAYJS::JSAST
  class LocalVariableAssignmentNode < Furnace::AST::Node
    def initialize(variable, value)
      super :var_assign, [ variable, value ]
    end
  end
end