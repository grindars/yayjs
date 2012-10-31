module YAYJS::JSAST
  class ArgumentListNode < Furnace::AST::Node

    def initialize(children)
      super :argument_list, children
    end
  end
end