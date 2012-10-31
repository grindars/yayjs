module YAYJS::Instructions

  class Setdynamic < Instruction
    dindex  :idx
    rb_num  :level

    pops  1
    pushes  0
  end
end
