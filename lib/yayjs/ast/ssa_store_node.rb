module YAYJS::AST

  class SSAStoreNode < Furnace::AST::Node
    attr_reader :variable

    def initialize(variable, value)
      super :ssa_store, [ value ], { variable: variable }
    end

    def fancy_type
      "ssa-store #{@variable}"
    end
  end

end