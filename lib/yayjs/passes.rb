require_relative "passes/cfg_pass.rb"
require_relative "passes/ast_pass.rb"

require_relative "passes/expand_stack_operations.rb"
require_relative "passes/merge_phi_nodes.rb"
require_relative "passes/cleanup_graph.rb"

require_relative "passes/merge_blocks.rb"
require_relative "passes/generate_javascript.rb"
require_relative "passes/expand_instructions.rb"
require_relative "passes/fold_ast.rb"
