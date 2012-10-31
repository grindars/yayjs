module YAYJS::Instructions

  class Putstring < Instruction
    literal :string
    pops  0
    pushes  1
  end
end
