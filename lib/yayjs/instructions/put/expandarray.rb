module YAYJS::Instructions

  class Expandarray < Instruction
    rb_num  :num
    rb_num  :flags

    pops  1
    pushes  ->(op) { op.num + ((op.flags & 1) == 1 ? 1 : 0) }
  end
end
