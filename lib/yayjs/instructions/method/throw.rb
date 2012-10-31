module YAYJS::Instructions

  class Throw < Instruction
    rb_num  :throw_state

    pops  1
    pushes  1
  end
end
