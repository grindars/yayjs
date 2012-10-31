module YAYJS::AST

  class LiteralNode < Furnace::AST::Node
    attr_reader :value

    def initialize(value)
      super :literal, [ ], { value: value }
    end

    def fancy_type
      "literal #{value.inspect}"
    end
  end

end