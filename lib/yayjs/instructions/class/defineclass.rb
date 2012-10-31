module YAYJS::Instructions

  class Defineclass < Instruction
    symbol  :id
    iseq  :class_iseq
    rb_num  :define_type

    pops  2
    pushes  1
  end
end
