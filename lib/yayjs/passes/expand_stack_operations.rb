module YAYJS::Passes
  class ExpandStackOperations < CFGPass
    def process(graph)
      super

      @renames = []

      @graph.nodes.each do |node|
        node.instructions.reject! do |instruction|
          drop = true

          if instruction.kind_of?(YAYJS::Instructions::Pop) || instruction.kind_of?(YAYJS::Instructions::Adjuststack)

          elsif instruction.kind_of? YAYJS::Instructions::Setn
            (0...instruction.n).each { |index| rename instruction.results[index], instruction.args[index] }

            rename instruction.results[instruction.n], instruction.args[0]
          else
            drop = false
          end

          drop
        end
      end

      commit_renames

      @graph.nodes.each do |node|
        node.instructions.reject! do |instruction|
          drop = true

          if instruction.kind_of? YAYJS::Instructions::Dup
            rename instruction.results[0], instruction.args[0]
            rename instruction.results[1], instruction.args[0]

          elsif instruction.kind_of? YAYJS::Instructions::Dupn
            (0...instruction.n).each do |index|
              rename instruction.results[index], instruction.args[index]
              rename instruction.results[index * 2], instruction.args[index]
            end

          elsif instruction.kind_of? YAYJS::Instructions::Topn
            rename instruction.results.first, instruction.args[instruction.n]
            (0..instruction.n).each do |index|
              rename instruction.results[index + 1], instruction.args[index]
            end

          elsif instruction.kind_of? YAYJS::Instructions::Swap
            rename instruction.results[0], instruction.args[1]
            rename instruction.results[1], instruction.args[0]

          else
            drop = false
          end

          drop
        end
      end

      commit_renames
    end

    protected

    def rename(src, dest)
      @renames.each_with_index do |(isrc, idest), idx|
        if isrc == src
          src = idest
        elsif isrc == dest
          dest = idest
        end
      end

      @renames << [ src, dest ]
    end

    def commit_renames
      return if @renames.empty?

      renames_hash = Hash[@renames]

      @graph.nodes.each do |node|
        node.instructions.each_with_index do |instruction, index|
          instruction.args.each_with_index do |name, name_index|
            name = renames_hash[name]

            instruction.args[name_index] = name unless name.nil?
          end

          instruction.results.each_with_index do |name, name_index|
            name = renames_hash[name]

            instruction.results[name_index] = name unless name.nil?
          end
        end
      end


      @renames = []
    end
  end
end
