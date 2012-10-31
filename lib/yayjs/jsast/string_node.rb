module YAYJS::JSAST
  class StringNode < Furnace::AST::Node
    attr_reader :value

    def initialize(value)
      super :string, [], { value: value }
    end

    def fancy_type
      "string #{@value}"
    end
  end
end