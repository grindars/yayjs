module YAYJS::Instructions

  class Jump < Instruction
    symbol  :dst

    pops  0
    pushes  0
  end
end
