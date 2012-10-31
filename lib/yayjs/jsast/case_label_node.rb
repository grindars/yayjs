module YAYJS::JSAST
  class CaseLabelNode < Furnace::AST::Node

    def initialize(value)
      super :case_label, [ value ]
    end

    def fancy_type
      "case-label"
    end
  end
end