module YAYJS::JSAST
  class PropertyAccessNode < Furnace::AST::Node
    def initialize(children)
      super :property_access, children
    end
  end
end