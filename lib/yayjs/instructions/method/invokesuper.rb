module YAYJS::Instructions

  class Invokesuper < Instruction
    rb_num  :op_argc
    iseq  :blockiseq
    rb_num  :op_flag

    pops  ->(op) { 1 + op.op_argc + (op_flag & 4) ? 1 : 0 }
    pushes  1
  end
end
