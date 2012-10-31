module YAYJS::Instructions

  class Setglobal < Instruction
    gentry  :entry

    pops  1
    pushes  0
  end
end
