module YAYJS::AST

  class SSAFetchNode < Furnace::AST::Node
    attr_reader :variable

    def initialize(variable)
      super :ssa_fetch, [], { variable: variable }
    end

    def fancy_type
      "ssa-fetch #{@variable}"
    end
  end

end