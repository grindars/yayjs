module YAYJS::Instructions

  class OptCaseDispatch < Instruction
    cdhash  :target_hash
    symbol  :else_offset

    pops  1
    pushes  0
  end
end
