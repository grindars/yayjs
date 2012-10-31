module YAYJS::Instructions

  class Setn < Instruction
    rb_num  :n
    pops  ->(op) { op.n + 1 }
    pushes  ->(op) { op.n + 1 }
  end
end
