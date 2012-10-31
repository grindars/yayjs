module YAYJS::JSAST
  class ContinueNode < Furnace::AST::Node
    attr_reader :label

    def initialize(label = nil)
      super :continue, [], { label: label }
    end

    def fancy_type
      if label.nil?
        super
      else
        "continue #{label}"
      end
    end
  end
end