module YAYJS::Instructions

  class Newrange < Instruction
    rb_num  :flag
    pops  2
    pushes  1
  end
end
