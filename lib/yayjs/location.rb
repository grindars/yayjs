module YAYJS
  class Location
    attr_reader :name, :path, :line

    def initialize(name, path, line)
      @name = name
      @path = path
      @line = line

      freeze
    end

    GENERATED = Location.new "<generated>", "<generated>", 1
  end
end
