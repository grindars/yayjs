module YAYJS::JSAST
  class BooleanNode < Furnace::AST::Node
    attr_reader :value

    def initialize(value)
      super :value, [], { value: value }
    end

    def fancy_type
      "boolean #{value.inspect}"
    end
  end
end