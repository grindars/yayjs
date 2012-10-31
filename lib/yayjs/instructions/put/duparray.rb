module YAYJS::Instructions

  class Duparray < Instruction
    literal :ary
    pops  0
    pushes  1
  end
end
