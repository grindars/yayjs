module YAYJS::Instructions

  class Topn < Instruction
    rb_num  :n
    pops  ->(op) { op.n + 1 }
    pushes  ->(op) { op.n + 2 }
  end
end
