module YAYJS::Instructions

  class ExceptionDispatch < Instruction
    symbol  :type
    rb_num  :sp
    symbol  :dst

    pops  0
    pushes  ->(op) { op.sp }
  end
end
