module YAYJS::Instructions

  class Newarray < Instruction
    rb_num  :num
    pops  ->(op) { op.num }
    pushes  1
  end
end
