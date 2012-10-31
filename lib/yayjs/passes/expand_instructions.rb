module YAYJS::Passes
  class ExpandInstructions < ASTPass

    # TODO:
    # - exception_dispatch/exception_rethrow
    # - are we using IC or not?

    def process_genericinstructionnode(node)
      instruction_class = node.instruction.instruction.class.name.split("::").last

      insn_expander = :"expand_#{instruction_class.downcase}"
      args_expander = :"args_#{instruction_class.downcase}"
      if respond_to? insn_expander
        send insn_expander, node.instruction.instruction, node
      else
        if respond_to? args_expander
          parameters = send args_expander, node.instruction.instruction
        else
          parameters = generic_expander node.instruction.instruction
        end

        YAYJS::AST::InstructionNodes.const_get(:"#{instruction_class}Node").new parameters + node.children.map { |n| process n }
      end
    end

    def generic_expander(insn)
      insn.class.instruction_parameters.map do |type, name|
        value = insn.send name

        case type
        when :lindex, :dindex, :gentry, :rb_num, :symbol, :literal

          YAYJS::AST::LiteralNode.new value

        when :ic
          nil

        when :iseq

          if value.nil?
            YAYJS::AST::LiteralNode.new nil
          else
            YAYJS::Compiler.currently_serving.compile_iseq value
          end

        else
          raise "Unimplemented parameter type #{type}"
        end
      end.reject(&:nil?)
    end

    def expand_duparray(insn, node)
      YAYJS::AST::LiteralNode.new insn.ary
    end

    def expand_putiseq(insn, node)
      YAYJS::Compiler.currently_serving.compile_iseq insn.iseq
    end

    def expand_putnil(insn, node)
      YAYJS::AST::LiteralNode.new nil
    end

    def expand_putobject(insn, node)
      YAYJS::AST::LiteralNode.new insn.value
    end

    def expand_putstring(insn, node)
      YAYJS::AST::LiteralNode.new insn.string
    end
  end
end

