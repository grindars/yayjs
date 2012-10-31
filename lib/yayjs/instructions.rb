require_relative "instructions/instruction.rb"

[
  'nop', 'variable', 'put', 'stack', 'setting', 'class', 'method',
  'exception', 'jump', 'optimize'
].each do |category|
  Dir[File.join File.dirname(__FILE__), "instructions", category, "*.rb"].each do |filename|
    require_relative filename
  end
end