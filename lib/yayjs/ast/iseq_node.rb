module YAYJS::AST

  class ISeqNode < Furnace::AST::Node
    attr_reader :iseq

    def initialize(iseq, block)
      super :iseq, [ block ], { iseq: iseq }
    end
  end

end