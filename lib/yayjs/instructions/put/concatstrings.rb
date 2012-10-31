module YAYJS::Instructions

  class Concatstrings < Instruction
    rb_num  :num
    pops  ->(op) { op.num }
    pushes  1
  end
end
