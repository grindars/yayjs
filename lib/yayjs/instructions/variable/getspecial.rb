module YAYJS::Instructions

  class Getspecial < Instruction
    literal :key
    rb_num  :type

    pops  0
    pushes  1
  end
end
