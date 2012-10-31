module YAYJS
  class SSAInstructionDecorator
    attr_reader :instruction, :args, :results

    def initialize(instruction, args, results)
      @instruction = instruction
      @args = args
      @results = results

      freeze
    end

    def method_missing(m, *args, &block)
      if @instruction.respond_to? m
        return @instruction.send m, *args, &block
      else
        super
      end
    end

    def kind_of?(type)
      super || @instruction.kind_of?(type)
    end
      
    def inspect
      results = @results.map(&:to_s)
      arguments = @args.map(&:to_s)

      if results.empty?
        prefix = ""
      else
        prefix = "#{results.join ", "} = "
      end

      instruction = @instruction.inspect
      args = "(#{arguments.join ", "})"

      sprintf "%-16s%-48s%s", prefix, instruction, args
    end
  end
end