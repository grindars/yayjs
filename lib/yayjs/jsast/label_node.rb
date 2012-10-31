module YAYJS::JSAST
  class LabelNode < Furnace::AST::Node
    attr_reader :name

    def initialize(name, expression)
      super :label, [ expression ], { name: name }
    end

    def fancy_type
      "label #{@name}"
    end
  end
end