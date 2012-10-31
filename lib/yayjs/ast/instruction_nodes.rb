module YAYJS::AST
  class BaseInstructionNode < Furnace::AST::Node
    def initialize(children)
      super self.class.class_variable_get(:@@node_type), children
    end
  end

  module InstructionNodes
  end


  YAYJS::Instructions.constants.each do |class_name|
    next if class_name == :Instruction

    node_class = Class.new(BaseInstructionNode)

    node_class.class_variable_set :@@node_type, class_name.to_s.downcase.to_sym

    InstructionNodes.const_set :"#{class_name}Node", node_class
  end
end
