module YAYJS::Instructions

  class Setinstancevariable < Instruction
    symbol  :id
    ic    :ic

    pops  1
    pushes  0
  end
end
