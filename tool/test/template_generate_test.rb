require "kilau"
require_relative "../kilau_tool/template_compile"
T = Kilau::Testing

# test/fixtures/app/assets/views is compiled into the app's build/gen;
# the result must equal the committed test/fixtures/templates.rb, which
# template_runtime_test.rb runs.
app = "test/fixtures/app"
path = KilauTool::TemplateCompile.generate(app)
T.check("generate returns the file it wrote") { path == "test/fixtures/app/build/gen/templates.rb" }
T.check("the output matches the committed fixture") { File.read(path) == File.read("test/fixtures/templates.rb") }

def generate_error(dir)
  KilauTool::TemplateCompile.generate(dir)
  ""
rescue ArgumentError => e
  e.message
end

T.check("an app without assets/views is refused") { generate_error("/tmp/kilau-no-app") == "no template directory at /tmp/kilau-no-app/assets/views" }

broken = "/tmp/kilau-templates-#{Process.pid}"
Dir.mkdir(broken) unless File.directory?(broken)
Dir.mkdir(broken + "/assets") unless File.directory?(broken + "/assets")
Dir.mkdir(broken + "/assets/views") unless File.directory?(broken + "/assets/views")
T.check("an empty views directory is refused") { generate_error(broken).include?("no templates under") }
File.write(broken + "/assets/views/bad.html", "{#- args: -#}\n{{ nope }}\n")
T.check("a broken template names itself") { generate_error(broken).start_with?("bad.html:2: nope is not an argument") }
T.check("nothing is written when a template fails") { !File.exist?(broken + "/build/gen/templates.rb") }
File.delete(broken + "/assets/views/bad.html")
Dir.rmdir(broken + "/assets/views")
Dir.rmdir(broken + "/assets")
Dir.rmdir(broken)
