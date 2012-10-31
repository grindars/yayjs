module YAYJS::Passes
  class GenerateJavaScript < ASTPass
    include YAYJS::JSAST

    class StackNode
      attr_reader :iseq, :level
      attr_accessor :last_loop_id, :variables, :ruby_argc

      def initialize(iseq, level)
        @iseq = iseq
        @level = level

        @last_loop_id = 0
        @variables = Set[]
        @ruby_argc = nil
      end
    end

    def initialize
      super

      @stack = []
    end

    def next_loop_id
      node = @stack.last

      node.last_loop_id += 1

      node.last_loop_id
    end

    def this_loop_id
      @stack.last.last_loop_id
    end

    def ssa_var_to_js(ssa_variable)
      name, version = ssa_variable.to_s.split "."

      "ssa_#{name}_#{version}"
    end

    def variable_exists?(name)
      @stack.last.variables.include? name
    end

    def create_variable(name)
      @stack.last.variables.add name
    end

    def handler_for_instruction(insn)
      insn.class.name.split("::").last.sub(/Node$/, '').downcase
    end

    def call_ruby(method, args)
      FunctionCallNode.new(
        fetch_ruby(method),
        ArgumentListNode.new(args)
      )
    end

    def fetch_ruby(name)
      PropertyAccessNode.new([
        VariableNode.new("this"),
        VariableNode.new(name)
      ])
    end

    def node_for_literal(value)
      case value
      when Symbol
        call_ruby "intern", [ StringNode.new(value.to_s) ]

      when String
        call_ruby "lit_string", [ StringNode.new(value) ]

      when Numeric
        call_ruby "lit_numeric", [ NumberNode.new(value) ]

      when Array
        call_ruby "lit_array", value.map { |v| node_for_literal v }

      when Range
        call_ruby "lit_range", [
          NumberNode.new(value.min),
          NumberNode.new(value.max),
          BooleanNode.new(value.exclude_end?)
        ]

      when true
        fetch_ruby "Strue"

      when false
        fetch_ruby "Sfalse"

      when nil
        fetch_ruby "Snil"

      else
        raise "Cannot represent #{value.inspect} as literal"
      end
    end


    def lvar_name(lvar, level = @stack.last.level)
      if level == 0
        "local_#{lvar}"
      else
        "block#{level}_#{lvar}"
      end
    end

    def lvar_name_from_index(idx)
      iseq = @stack.last.iseq

      lvar_name iseq.locals[iseq.misc[:local_size] - idx]
    end

    def number_or_null(number)
      if number.nil?
        NullNode.new
      else
        NumberNode.new number
      end
    end

    def process_iseqnode(node)
      if node.iseq.type == :block
        raise "Block iseq on empty stack" if @stack.empty?

        level = @stack.last.level + 1
      else
        level = 0
      end

      @stack.push StackNode.new(node.iseq, level)

      begin

        children = []

        node.iseq.locals.each do |local|
          local = lvar_name local

          create_variable local
          children << LocalVariableAssignmentNode.new(
            VariableNode.new(local),
            fetch_ruby("Snil")
          )
        end

        create_variable "expanding_array"
        children << LocalVariableAssignmentNode.new(
          VariableNode.new("expanding_array"),
          NullNode.new
        )

        if node.iseq.args.kind_of? Fixnum
          argcheck_min = node.iseq.args
          argcheck_max = node.iseq.args
          static_args = node.iseq.args

        else
          static_args, opt_labels, post_len, post_start, rest, block, simple = node.iseq.args

          special_args = 0
          special_args += 1 if block != -1

          argcheck_min = static_args + special_args
          argcheck_max = static_args + special_args + opt_labels.length - 1

          if argcheck_min != argcheck_max
            cases = []

            (argcheck_max - special_args).downto(argcheck_min + 1 - special_args) do |arg_count|
              cases << CaseLabelNode.new(NumberNode.new(arg_count + 1))

              cases << VariableAssignmentNode.new(
                VariableNode.new(lvar_name(node.iseq.locals[arg_count - 1])),
                ArraySubscriptNode.new(
                  VariableNode.new("arguments"),
                  NumberNode.new(arg_count)
                )
              )
            end

            children << SwitchNode.new(
              PropertyAccessNode.new([
                VariableNode.new("arguments"),
                VariableNode.new("length")
              ]),

              BlockNode.new(cases)
            )
          end


          if rest != -1
            slice_args = [ NumberNode.new(argcheck_max) ]

            if special_args > 0
              slice_args << NumberNode.new(-special_args)
            end

            children << VariableAssignmentNode.new(
              VariableNode.new(lvar_name(node.iseq.locals[rest])),
              call_ruby("lit_array", [
                FunctionCallNode.new(
                  PropertyAccessNode.new([
                    VariableNode.new("Array"),
                    VariableNode.new("prototype"),
                    VariableNode.new("slice"),
                    VariableNode.new("call"),
                  ]),
                  ArgumentListNode.new([
                    VariableNode.new("arguments"),
                    *slice_args
                  ])
                )
              ])
            )

            argcheck_max = nil
          end

          if block != -1
            children << VariableAssignmentNode.new(
              VariableNode.new(lvar_name(node.iseq.locals[block])),
              ArraySubscriptNode.new(
                VariableNode.new("arguments"),
                BinaryOperatorNode.new(:"-",
                  PropertyAccessNode.new([
                    VariableNode.new("arguments"),
                    VariableNode.new("length")
                  ]),
                  NumberNode.new(1)
                )
              )
            )
          end

          @stack.last.ruby_argc = call_ruby("lit_numeric", [
            BinaryOperatorNode.new(:"-",
              PropertyAccessNode.new([
                VariableNode.new("arguments"),
                VariableNode.new("length")
              ]),
              NumberNode.new(special_args + 1)
            )
          ])
        end

        argcheck_min, argcheck_max = [ argcheck_min, argcheck_max ].map { |v| number_or_null v }

        children.unshift call_ruby("argcheck", [
          PropertyAccessNode.new([
            VariableNode.new("arguments"),
            VariableNode.new("length")
          ]),
          argcheck_min,
          argcheck_max
        ])

        node.iseq.locals[0...static_args].each_with_index do |local, idx|
          children << VariableAssignmentNode.new(
            VariableNode.new(lvar_name(local)),
            ArraySubscriptNode.new(
              VariableNode.new("arguments"),
              NumberNode.new(idx + 1)
            )
          )
        end

        children += node.children[0].children.map { |n| process(n) }

        FunctionNode.new(
          ArgumentListNode.new([
            VariableNode.new("self")
          ]),

          BlockNode.new(children)
        )
      ensure
        @stack.pop
      end
    end

    def process_blocknode(node)
      BlockNode.new node.children.map { |n| process(n) }
    end

    def process_preconditionloopnode(node)
      generate_loop node, :precondition
    end

    def process_postconditionloopnode(node)
      generate_loop node, :postcondition
    end

    def process_infiniteloopnode(node)
      generate_loop node, :infinite
    end

    def generate_loop(node, type)
      loop_id = next_loop_id

      loop_inner_stuff    = [ ]
      loop_outer_pre_stuff  = [ ]
      loop_outer_post_stuff = [ ]

      case type
      when :precondition
        loop_outer_pre_stuff  = node.children[0].children
        loop_inner_stuff    = node.children[1].children

      when :postcondition
        loop_inner_stuff    = node.children[0].children
        loop_outer_post_stuff = node.children[1].children

      when :infinite
        loop_inner_stuff    = node.children[0].children
      end

      [ loop_outer_pre_stuff, loop_inner_stuff, loop_outer_post_stuff ].each do |list|
        list.map! { |node| process node }
      end

      LabelNode.new(
        "__loop_outer_#{loop_id}",
        WhileNode.new(
          BooleanNode.new(true),
          BlockNode.new([
            *loop_outer_pre_stuff,
            LabelNode.new(
              "__loop_inner_#{loop_id}",
              WhileNode.new(
                BooleanNode.new(true),
                BlockNode.new([
                  TryNode.new([
                    BlockNode.new(loop_inner_stuff),
                    CatchNode.new(
                      VariableNode.new("e"),
                      BlockNode.new([
                        SwitchNode.new(
                          call_ruby("loop_exception", [
                            VariableNode.new("e"),
                          ]),
                          BlockNode.new([
                            CaseLabelNode.new(
                              NumberNode.new(0)
                            ),
                            ContinueNode.new(
                              "__loop_outer_#{loop_id}"
                            ),
                            CaseLabelNode.new(
                              NumberNode.new(1)
                            ),
                            BreakNode.new(
                              "__loop_outer_#{loop_id}"
                            ),
                            CaseLabelNode.new(
                              NumberNode.new(2)
                            ),
                            ContinueNode.new(
                              "__loop_inner_#{loop_id}"
                            ),
                            CaseDefaultLabelNode.new,
                            ThrowNode.new(
                              VariableNode.new("e"),
                            )
                          ])
                        )
                      ])
                    )
                  ]),
                  BreakNode.new
                ])
              )
            ),
            *loop_outer_post_stuff
          ])
        )
      )
    end

    def process_ifnode(node)
      IfNode.new *node.children.map { |n| process(n) }
    end

    def process_casenode(node)
      block_contents = []

      node.children[1..-1].each do |child_node|
        block_contents << case child_node
        when YAYJS::AST::CaseWhenNode
          CaseLabelNode.new(
            FunctionCallNode.new(
              PropertyAccessNode.new([
                node_for_literal(child_node.value),
                VariableNode.new("switchvar")
              ]),
              ArgumentListNode.new([])
            )
          )

        when YAYJS::AST::CaseElseNode
          CaseDefaultLabelNode.new

        else
          raise "Unexpected node in case: #{child_node.inspect}"
        end

        block_contents += child_node.children[0].children.map { |n| process n }
        block_contents << BreakNode.new
      end

      SwitchNode.new(
        FunctionCallNode.new(
          PropertyAccessNode.new([
            process(node.children[0]),
            VariableNode.new("switchvar")
          ]),
          ArgumentListNode.new([])
        ),
        BlockNode.new(block_contents)
      )
    end

    def process_casewhennode(node)
      raise "GenerateJavaScript should not see CaseWhenNode"
    end

    def process_caseelsenode(node)
      raise "GenerateJavaScript should not see CaseElseNode"
    end

    def process_ssastorenode(node)
      var = ssa_var_to_js node.variable
      if variable_exists? var
        VariableAssignmentNode.new(
          VariableNode.new(var),
          process(node.children[0])
        )
      else
        create_variable var

        LocalVariableAssignmentNode.new(
          VariableNode.new(var),
          process(node.children[0])
        )
      end
    end

    def process_ssastoremultiplenode(node)
      assignments = []

      node.variables.each_with_index do |var, index|
        var = ssa_var_to_js var

        if variable_exists? var
          onode = VariableAssignmentNode.new(
              VariableNode.new(var),
              ArraySubscriptNode.new(
                VariableNode.new("expanding_array"),
                NumberNode.new(index)
              )
          );
        else
          create_variable var

          onode = LocalVariableAssignmentNode.new(
              VariableNode.new(var),
              ArraySubscriptNode.new(
                VariableNode.new("expanding_array"),
                NumberNode.new(index)
              )
          );
        end

        assignments << onode
      end

      BlockNode.new([
        VariableAssignmentNode.new(
          VariableNode.new("expanding_array"),
          process(node.children[0])
        ),

        *assignments,

        VariableAssignmentNode.new(
          VariableNode.new("expanding_array"),
          NullNode.new
        )
      ])
    end

    def process_ssafetchnode(node)
      var = ssa_var_to_js node.variable
      raise "variable not exists" if !variable_exists? var

      VariableNode.new var
    end

    def process_breaknode(node)
      loop_id = this_loop_id

      BreakNode.new "__loop_outer_#{loop_id}"
    end

    def process_redonode(node)
      loop_id = this_loop_id

      ContinueNode.new "__loop_inner_#{loop_id}"
    end

    def process_nextnode(node)
      loop_id = this_loop_id

      ContinueNode.new "__loop_outer_#{loop_id}"
    end

    def process_baseinstructionnode(node)
      handler = handler_for_instruction node
      handler_func = :"handle_#{handler}"

      if respond_to? handler_func
        send handler_func, node
      else
        call_ruby handler, node.children.map { |n| process n }
      end
    end

    def process_leavenode(node)
      ReturnNode.new process(node.children[0])
    end

    def process_literalnode(node)
      node_for_literal node.value
    end

    def handle_getlocal(node)
      index = node.children[0].value

      if index < 0
        case -index
        when 1    # Argument count
          @stack.last.ruby_argc

        else
          raise "undefined internal lvar #{index}"
        end
      else
        VariableNode.new lvar_name_from_index(index)
      end
    end

    def handle_setlocal(node)
      index = node.children[0].value

      raise "attempted to set internal lvar" if index < 0

      VariableAssignmentNode.new(
        VariableNode.new(lvar_name_from_index(index)),
        process(node.children[1])
      )
    end

    def resolve_dynvar(index, level)
      raise "dynvar is too deep" if level > @stack.last.level

      frame = @stack[-level - 1]
      varname = frame.iseq.locals[frame.iseq.misc[:local_size] - index]

      lvar_name varname, frame.level
    end

    def handle_getdynamic(node)
      index, level = node.children.map(&:value)

      VariableNode.new resolve_dynvar(index, level)
    end

    def handle_setdynamic(node)
      index, level = node.children[0..1].map(&:value)
      value    = node.children[2]

      VariableAssignmentNode.new(
        VariableNode.new(resolve_dynvar(index, level)),
        process(value)
      )
    end

    def handle_putself(node)
      VariableNode.new "self"
    end
  end

end

