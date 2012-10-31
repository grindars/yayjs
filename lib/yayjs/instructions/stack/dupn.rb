module YAYJS::Instructions

  class Dupn < Instruction
    rb_num  :n
    pops  ->(op) { op.n }
    pushes  ->(op) { 2 * op.n }
  end
end
