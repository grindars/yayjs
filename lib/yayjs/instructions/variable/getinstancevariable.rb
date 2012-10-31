module YAYJS::Instructions

  class Getinstancevariable < Instruction
    symbol  :id
    ic    :ic

    pops  0
    pushes  1
  end
end
