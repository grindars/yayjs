module YAYJS::JSAST
  class BinaryOperatorNode < Furnace::AST::Node
    attr_reader :type

    def initialize(type, left, right)
      super :binary, [ left, right ], { type: type }
    end

    def fancy_type
      "binary #{@type}"
    end
  end
end