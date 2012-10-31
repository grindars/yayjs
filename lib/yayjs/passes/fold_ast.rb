module YAYJS::Passes
  class FoldAST < ASTPass
    # Not complete.

    class CollectSSAPass < ASTPass
      attr_reader :vars

      def initialize
        @vars = nil

        super
      end

      def process_iseqnode(node)
        @vars = Hash.new { 0 }

        ret = super

        @vars.default = nil

        ret
      end

      def process_ssafetchnode(node)
        @vars[node.variable] += 1
      end
    end

    def initialize
      @collect = CollectSSAPass.new
      @vars = nil
      @captures = nil

      super
    end

    def process_iseqnode(node)
      @collect.process node

      @vars = Set[]
      @collect.vars.each { |k, v| @vars.add(k) if v == 1 }

      @captures = {}

      super
    end

    def process_ssastorenode(node)
      if @vars.include? node.variable
        @captures[node.variable] = process(node.children[0])

        nil
      else
        super
      end
    end

    def process_ssafetchnode(node)
      if @captures.include? node.variable
        @captures[node.variable]
      else
        super
      end
    end

    def process_blocknode(node)
      YAYJS::AST::BlockNode.new node.children.map { |n| process(n) }.reject(&:nil?)
    end
  end
end
