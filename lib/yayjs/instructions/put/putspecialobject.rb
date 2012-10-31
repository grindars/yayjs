module YAYJS::Instructions

  class Putspecialobject < Instruction
    rb_num  :value_type
    pops  0
    pushes  1
  end
end
