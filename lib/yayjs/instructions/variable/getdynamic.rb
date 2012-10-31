module YAYJS::Instructions

  class Getdynamic < Instruction
    dindex  :idx
    rb_num  :level

    pops  0
    pushes  1
  end
end
