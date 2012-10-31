module YAYJS::AST

  class CaseWhenNode < Furnace::AST::Node
    attr_reader :value

    def initialize(value, block)
      super :case_when, [ block ], { value: value }
    end

    def fancy_type
      "case-when #{@variable}"
    end
  end

end