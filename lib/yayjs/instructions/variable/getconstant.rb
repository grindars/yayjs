module YAYJS::Instructions

  class Getconstant < Instruction
    symbol  :id

    pops  1
    pushes  1
  end
end
