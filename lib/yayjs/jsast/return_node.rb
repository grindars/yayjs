module YAYJS::JSAST
  class ReturnNode < Furnace::AST::Node
    def initialize(value)
      super :return, [ value ]
    end
  end
end