module YAYJS::Instructions

  class Newhash < Instruction
    rb_num  :num
    pops  ->(op) { op.num }
    pushes  1
  end
end
