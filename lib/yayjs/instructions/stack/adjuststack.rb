module YAYJS::Instructions

  class Adjuststack < Instruction
    rb_num  :n
    pops  ->(op) { op.n }
    pushes  0
  end
end
