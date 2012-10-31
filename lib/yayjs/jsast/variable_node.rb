module YAYJS::JSAST
  class VariableNode < Furnace::AST::Node
    attr_reader :name

    def initialize(name)
      super :variable, [], { name: name }
    end

    def fancy_type
      "variable #{name}"
    end
  end
end