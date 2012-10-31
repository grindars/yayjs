module YAYJS::Instructions
  class Instruction
    def self.class_writer(*names)
      names.each do |name|
        cvar = :"@@#{name}"
        define_singleton_method(name) { |value| class_variable_set cvar, value }
      end
    end

    def self.parameter_definer(*names)
      names.each do |name|
        define_singleton_method(name) { |identifier| define_parameter name, identifier }
      end
    end

    class_writer :pops, :pushes
    parameter_definer :lindex, :dindex, :gentry, :rb_num, :ic, :symbol, :literal, :iseq, :cdhash
    attr_reader :pops, :pushes, :location

    def initialize(location, args = [])
      @location = location

      if self.class.class_variable_defined? :@@parameters
        parameters = self.class.class_variable_get :@@parameters

        if parameters.length != args.length
          raise "#{args.length} parameters in bytecode, #{parameters.length} expected"
        end

        parameters.each_with_index do |(type, identifier), index|
          value = args[index]

          if !send :"is_valid_#{type}", value
            raise "Invalid type: #{type} expected, #{value} passed"
          end

          convert = :"convert_#{type}"
          if respond_to? convert, true
            value = send convert, value
          end

          value.freeze

          instance_variable_set :"@#{identifier}", value
        end
      elsif args.length != 0
        raise "#{args.length} parameters in bytecode, none expected"
      end

      [
        :@pops, :@pushes
      ].each do |var|
        val = self.class.class_variable_get :"@#{var}"
        val = val.call(self) if val.kind_of? Proc
        instance_variable_set var, val
      end

      freeze
    end

    def is_valid_lindex(value)
      value.kind_of? Fixnum
    end

    def is_valid_dindex(value)
      value.kind_of? Fixnum
    end

    def is_valid_rb_num(value)
      value.kind_of? Integer
    end

    def is_valid_ic(value)
      value.kind_of? Fixnum
    end

    def is_valid_symbol(value)
      value.kind_of? Symbol
    end

    def is_valid_literal(value)
      true
    end

    def is_valid_iseq(value)
      value.nil? or value.kind_of? Array
    end

    def convert_iseq(value)
      return nil if value.nil?

      YAYJS::ISeq.from_yarv value
    end

    def is_valid_cdhash(value)
      value.kind_of?(Array) && (value.length % 2) == 0
    end

    def convert_cdhash(value)
      hash = {}

      (0...value.length).step(2) do |i|
        whenval, label = value[i..i + 1]

        raise "Malformed CDHASH" unless is_valid_literal(whenval) && is_valid_symbol(label)

        hash[whenval] = label
      end

      hash
    end

    def inspect
      words = [ sprintf("%-16s", self.class.name.split('::').last.downcase!) ]

      if self.class.class_variable_defined? :@@parameters
        parameters = self.class.class_variable_get :@@parameters
      else
        parameters = []
      end

      args = []

      parameters.each do |parameter|
        val = instance_variable_get :"@#{parameter[1]}"

        args << val.inspect
      end

      words << args.join(", ")

      words.join " "
    end

    def self.instruction_parameters
      if class_variable_defined? :@@parameters
        class_variable_get :@@parameters
      else
        []
      end
    end

    protected

    def self.define_parameter(type, identifier)
      if class_variable_defined? :@@parameters
        parameters = class_variable_get :@@parameters
      else
        parameters = []
        class_variable_set :@@parameters, parameters
      end

      parameters << [ type, identifier ]

      attr_reader identifier.to_sym
    end
  end
end