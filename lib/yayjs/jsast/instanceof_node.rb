module YAYJS::JSAST
  class InstanceofNode < Furnace::AST::Node
    def initialize(value, class_value)
      super :instanceof, [ value, class_value ]
    end
  end
end