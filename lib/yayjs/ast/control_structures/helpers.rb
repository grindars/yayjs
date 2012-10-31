module YAYJS::AST::ControlStructures

  module Helpers
    def self.nearest_block(block, possibilites)
      queue = Set[]
      checked = Set[]

      queue.add block

      until queue.empty?
        new_queue = Set[]

        queue.each do |node|
          checked.add node

          return node if possibilites.include? node

          node.targets.each do |target|
            new_queue.add target unless checked.include? target
          end
        end

        queue = new_queue
      end

      nil
    end
  end
end