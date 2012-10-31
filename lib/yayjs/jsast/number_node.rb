module YAYJS::JSAST
  class NumberNode < Furnace::AST::Node
    attr_reader :value

    def initialize(value)
      super :number, [], { value: value }
    end

    def fancy_type
      "number #{@value}"
    end
  end
end