module YAYJS::Instructions

  class Send < Instruction
    symbol  :op_id
    rb_num  :op_argc
    iseq  :blockiseq
    rb_num  :op_flag
    ic    :ic

    pops  ->(op) { 1 + op.op_argc + ((op.op_flag & 4) == 4 ? 1 : 0) }
    pushes  1
  end
end
