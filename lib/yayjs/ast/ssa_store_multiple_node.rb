module YAYJS::AST

  class SSAStoreMultipleNode < Furnace::AST::Node
    attr_reader :variables

    def initialize(variables, value_producer)
      super :ssa_store_multi, [ value_producer ], { variables: variables }
    end

    def fancy_type
      "ssa-store-multi #{@variables.map(&:to_s).join(", ")}"
    end
  end

end