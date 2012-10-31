module YAYJS::Instructions

  class Getlocal < Instruction
    lindex  :idx

    pops  0
    pushes  1
  end
end
