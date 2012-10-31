module YAYJS::AST

  class GenericInstructionNode < Furnace::AST::Node
    attr_reader :instruction

    def initialize(instruction, children = [])
      super :instruction, children, { instruction: instruction }
    end

    protected

    def fancy_type
      if instruction.kind_of? YAYJS::SSAInstructionDecorator
        "insn #{instruction.instruction.inspect.strip}"
      else
        "insn #{instruction.inspect.strip}"
      end
    end
  end

end