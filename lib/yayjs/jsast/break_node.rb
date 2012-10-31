module YAYJS::JSAST
  class BreakNode < Furnace::AST::Node
    attr_reader :label

    def initialize(label = nil)
      super :break, [], { label: label }
    end

    def fancy_type
      if label.nil?
        super
      else
        "break #{label}"
      end
    end
  end
end