module YAYJS
  class Compiler
    @@working_compilers = []

    def initialize

      @ssa_passes = [
        Passes::ExpandStackOperations,
        Passes::MergePhiNodes,
        Passes::CleanupGraph,
      ]

      @ast_passes = [
        Passes::MergeBlocks,
        # Passes::FoldAST,
        Passes::ExpandInstructions
      ]

      @cfg_builder = CFGBuilder.new
      @ssa_builder = SSABuilder.new
      @ast_builder = AST::Builder.new
      @js_generator = Passes::GenerateJavaScript.new
      @js_printer = JSAST::Printer.new
    end

    def compile_iseq(iseq)
      @@working_compilers.push self

      begin
        graph = @cfg_builder.build iseq
        @ssa_builder.convert graph

        @ssa_passes.each { |pass| pass.new.process graph }

        ast = @ast_builder.build graph, iseq

        @ast_passes.each do |pass|
          ast = pass.new.process ast
        end

        ast
      ensure
        @@working_compilers.pop
      end
    end

    def compile_file(file)
      iseq = ISeq.from_yarv RubyVM::InstructionSequence.compile_file(file, {
        inline_const_cache:        false, # getinlinecache/setinlinecache
        instructions_unification:  true,
        operands_unification:      true,
        peephole_optimization:     true,
        specialized_instruction:   false, # opt* except opt_case_dispatch
        stack_caching:             false, # reput
        tailcall_optimization:     false,
        trace_instruction:         false, # trace
      })

      ast = compile_iseq iseq

      jsast = @js_generator.process ast

      @js_printer.process jsast
    end

    def self.currently_serving
      @@working_compilers.last
    end
  end
end
