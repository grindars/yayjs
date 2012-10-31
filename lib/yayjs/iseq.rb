module YAYJS
  class ISeq
    class ExceptionHandler
      attr_reader :type, :iseq, :area_start, :area_end, :cont, :sp

      def initialize(type, iseq, area_start, area_end, cont, sp)
        @type = type
        @iseq = iseq
        @area_start = area_start
        @area_end = area_end
        @cont = cont
        @sp = sp

        freeze
      end

      def inspect
        "<exception:#{type},#{area_start}-#{area_end},cont:#{cont},sp:#{sp}>"
      end
    end

    attr_reader :misc, :name, :path, :absolute_path, :type
    attr_reader :locals, :args, :exception_handlers, :bytecode

    ISEQ_MAJOR_VERSION = 1
    ISEQ_MINOR_VERSION = 2

    def initialize(array)
      magic, major_version, minor_version, format_type,
      @misc, @name, @path, @absolute_path, start_lineno, @type,
      @locals, @args, catch_table, bytecode = array

      if magic != "YARVInstructionSequence/SimpleDataFormat" ||
         major_version != ISEQ_MAJOR_VERSION ||
         minor_version != ISEQ_MINOR_VERSION ||
         format_type != 1

        raise "Unexpected format: #{type} #{major}.minor, #{format_type}"
      end

      @bytecode = to_instructions bytecode, start_lineno
      @exception_handlers = catch_table.map { |v| to_handler(v) }.reject { |v| v.nil? }

      if @args.kind_of?(Array) && @args[1].any?
        cdhash = []
        @args[1].each_with_index do |label, index|
          cdhash << index + @args[0]
          cdhash << label
        end

        getlocal      = Instructions::Getlocal.new            YAYJS::Location::GENERATED, [ -1 ]
        case_dispatch = Instructions::OptCaseDispatch.new     YAYJS::Location::GENERATED, [ cdhash[0...-2], :args_mismatch ]
        label         = Instructions::Label.new               YAYJS::Location::GENERATED, [ :args_mismatch ]
        jump          = Instructions::Jump.new                YAYJS::Location::GENERATED, [ @args[1].last ]

        @bytecode.unshift getlocal, case_dispatch, label, jump
      end

      @misc.freeze
      @name.freeze
      @path.freeze
      @absolute_path.freeze
      @locals.freeze
      @exception_handlers.freeze
      @bytecode.freeze

      freeze
    end

    def self.from_yarv(iseq)
      self.new iseq.to_a
    end

    private

    def to_instructions(bytecode, start_lineno)
      opcodes = []
      line = start_lineno

      bytecode.each do |op|
        case op
        when Integer
          line = op

        when Symbol
          opcodes << create_instruction([ :label, op ], Location.new(@name, @path, line))

        when Array
          opcodes << create_instruction(op, Location.new(@name, @path, line))

        else
          raise "Unexpected value in bytecode"
        end
      end

      opcodes
    end

    def to_handler(list)
      type, iseq, area_start, area_end, cont, sp = list

      return nil if [ :break, :next, :redo ].include? type

      iseq = ISeq.from_yarv iseq unless iseq.nil?

      ExceptionHandler.new type, iseq, area_start, area_end, cont, sp
    end

    def create_instruction(op, location)
      class_name = op[0].to_s.split('_').map! { |v| v.capitalize }.join.to_sym
      raise "Unknown instruction #{op[0]} (class #{class_name} not defined)" if !Instructions.const_defined? class_name

      instr = Instructions.const_get(class_name).new location, op[1..-1]

      instr.freeze
    end
  end
end
