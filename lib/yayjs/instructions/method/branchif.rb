module YAYJS::Instructions

  class Branchif < Instruction
    symbol  :dst

    pops  1
    pushes  0
  end
end
