module YAYJS::Passes
  class CleanupGraph < CFGPass
    def process(graph)
      super

      @graph.eliminate_unreachable!
      @graph.merge_redundant!
    end
  end
end
