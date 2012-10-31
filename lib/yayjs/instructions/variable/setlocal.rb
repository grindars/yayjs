module YAYJS::Instructions

  class Setlocal < Instruction
    lindex  :idx

    pops  1
    pushes  0
  end
end
