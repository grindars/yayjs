module YAYJS::Instructions

  class Invokeblock < Instruction
    rb_num  :num
    rb_num  :flag

    pops  ->(op) { num }
    pushes  1
  end
end
