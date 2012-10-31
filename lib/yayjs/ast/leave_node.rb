module YAYJS::AST

  class LeaveNode < Furnace::AST::Node
    def initialize(value)
      super :leave, [ value ]
    end
  end

end