module YAYJS::JSAST
  class Printer
    def initialize
      @block_level = 0
    end

    def indent(line = "", block_level = @block_level)
      level = [ 0, block_level ].max

      ("  " * level) + line
    end

    def children(node)
      node.children.map { |n| process n }
    end

    def process(node)
      send :"process_#{node.class.name.split("::").last.downcase}", node
    end

    def process_functionnode(node)
      args, body = children node

      "(function#{args}\n#{body})"
    end

    def process_argumentlistnode(node)
      "(#{children(node).join ", "})"
    end

    def process_variablenode(node)
      node.name
    end

    def process_blocknode(node)
      ret = indent "{\n"

      @block_level += 1

      begin
        ret += children(node).map do |text|
          if text.end_with?(':')
            indent text + "\n", @block_level - 1
          elsif text.end_with?('}')
            indent text + "\n"
          else
            indent text + ";\n"
          end
        end.join
      ensure
        @block_level -= 1
      end

      ret += indent "}"

      ret
    end

    def process_localvariableassignmentnode(node)
      var, value = children node

      "var #{var} = #{value}"
    end

    def process_variableassignmentnode(node)
      var, value = children node

      "#{var} = #{value}"
    end

    def process_nullnode(node)
      "null"
    end

    def process_breaknode(node)
      if node.label.nil?
        "break"
      else
        "break #{node.label}"
      end
    end

    def process_continuenode(node)
      if node.label.nil?
        "continue"
      else
        "continue #{node.label}"
      end
    end

    def process_returnnode(node)
      value, = children(node);

      "return #{value}"
    end

    def process_functioncallnode(node)
      children(node).join
    end

    def process_propertyaccessnode(node)
      children(node).join '.'
    end

    def process_arraysubscriptnode(node)
      array, index = children(node)

      "#{array}[#{index}]"
    end

    def process_numbernode(node)
      node.value.to_s
    end

    def process_stringnode(node)
      node.value.inspect
    end

    def process_switchnode(node)
      expr, body = children(node)

      "switch(#{expr})\n#{body}"
    end

    def process_caselabelnode(node)
      expr, = children(node)

      "case #{expr}:"
    end

    def process_casedefaultlabelnode(node)
      "default:"
    end

    def process_binaryoperatornode(node)
      left, right = children(node)

      "(#{left} #{node.type} #{right})"
    end

    def process_labelnode(node)
      body, = children node

      "#{node.name}: #{body}"
    end

    def process_whilenode(node)
      condition, body = children node

      "while(#{condition})\n#{body}"
    end

    def process_booleannode(node)
      case node.value
      when true
        "true"

      when false
        "false"
      end
    end

    def process_ifnode(node)
      condition, true_branch, false_branch = children node

      "if(#{condition})\n#{true_branch}\n#{indent}else\n#{false_branch}"
    end

    def process_trynode(node)
      "try\n#{children(node).join}"
    end

    def process_catchnode(node)
      var, body = children node

      "\n#{indent}catch(#{var})\n#{body}"
    end

    def process_instanceofnode(node)
      var, type = children node

      "#{var} instanceof #{type}"
    end

    def process_thrownode(node)
      value, = children node

      "throw #{value}"
    end
  end
end