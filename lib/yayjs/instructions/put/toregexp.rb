module YAYJS::Instructions

  class Toregexp < Instruction
    rb_num  :opt
    rb_num  :cnt
    pops  ->(op) { op.cnt }
    pushes  1
  end
end
