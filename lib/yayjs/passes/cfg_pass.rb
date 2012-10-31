module YAYJS::Passes
  class CFGPass
    def initialize
      @graph = nil
    end

    def process(graph)
      @graph = graph
    end
  end
end
