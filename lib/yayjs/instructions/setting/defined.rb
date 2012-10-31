module YAYJS::Instructions

  class Defined < Instruction
    rb_num  :type
    literal :obj
    literal :needstr

    pops  1
    pushes  1
  end
end
