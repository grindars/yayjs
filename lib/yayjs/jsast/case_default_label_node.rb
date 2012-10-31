module YAYJS::JSAST
  class CaseDefaultLabelNode < Furnace::AST::Node

    def initialize
      super :case_default_label
    end

    def fancy_type
      "case-default-label"
    end
  end
end