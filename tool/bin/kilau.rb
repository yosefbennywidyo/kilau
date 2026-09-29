# kilau: Kilau's build tool. Generators need no application code, so they
# live here rather than in each app's binary (spec §1, Binary).
require "kilau"
require_relative "../kilau_tool/entities_gen"
require_relative "../kilau_tool/template_compile"

USAGE = "usage: kilau gen entities <db-file> <out-dir>\n       kilau gen templates <app-dir>"

def kilau_main(argv)
  if argv.size == 4 && argv[0] == "gen" && argv[1] == "entities"
    KilauTool::EntitiesGen.generate(argv[2], argv[3]).each { |path| puts "wrote #{path}" }
    0
  elsif argv.size == 3 && argv[0] == "gen" && argv[1] == "templates"
    puts "wrote #{KilauTool::TemplateCompile.generate(argv[2])}"
    0
  else
    $stderr.puts USAGE
    2
  end
rescue ArgumentError, Kilau::DB::Error => e
  $stderr.puts "kilau: #{e.message}"
  1
end

exit kilau_main(ARGV)
