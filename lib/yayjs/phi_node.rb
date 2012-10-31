module YAYJS
  class PhiNode
    attr_reader :map

    def initialize(map, target)
      @map = map
      @target = target

      @map.freeze
      @target.freeze

      freeze
    end

    def args
      []
    end

    def results
      [ @target ]
    end

    def inspect
      map = @map.to_a.map { |(key, value)| "#{key}:#{value}" }.join(" ")

      sprintf "%-16s%s", "#{@target} =", "phi #{map}"
    end
  end
end