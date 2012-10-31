module YAYJS::Instructions

  class Putobject < Instruction
    literal :value
    pops  0
    pushes  1
  end
end
