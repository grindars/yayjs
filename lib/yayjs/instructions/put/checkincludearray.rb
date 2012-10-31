module YAYJS::Instructions

  class Checkincludearray < Instruction
    literal :flag

    pops  2
    pushes  2
  end
end
