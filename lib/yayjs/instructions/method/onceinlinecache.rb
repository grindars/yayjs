module YAYJS::Instructions

  class Onceinlinecache < Instruction
    symbol  :dst
    ic    :ic

    pops  0
    pushes  1
  end
end
