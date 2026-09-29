require "kilau"
require_relative "../kilau_tool/routes_gen"
T = Kilau::Testing

# test/fixtures/routes_app is compiled into its build/gen; the result must
# equal the committed test/fixtures/routes.rb, which routes_runtime_test.rb
# runs.
path = KilauTool::RoutesGen.generate("test/fixtures/routes_app")
T.check("generate returns the file it wrote") { path == "test/fixtures/routes_app/build/gen/routes.rb" }
T.check("the output matches the committed fixture") { File.read(path) == File.read("test/fixtures/routes.rb") }

# The message of the ArgumentError scanning and rendering these sources
# raises, or "" when they render. sources: path => source.
def gen_error(sources)
  scan = KilauTool::RoutesGen::Scan.new
  sources.keys.sort.each { |file| KilauTool::RoutesGen.scan_file(file, sources[file], scan) }
  KilauTool::RoutesGen.render(scan)
  ""
rescue ArgumentError => e
  e.message
end

APP = "class A < Kilau::Hooks\n  def routes = Kilau::AppRoutes.with_default_routes.add(C.routes)\nend\n"

def controller(line) = "class C < Kilau::Controller\n  def self.routes\n    Kilau::Routes.new\n      #{line}\n  end\nend\n"

T.check("a well-formed app renders") { gen_error({ "src/a.rb" => APP, "src/c.rb" => controller(".add(\"/x\", get { |a, r| x(a, r) })") }) == "" }
T.check("a block over several lines is refused with its line") do
  gen_error({ "src/a.rb" => APP, "src/c.rb" => controller(".add(\"/x\", get { |a, r|") }).include?("src/c.rb:4: a route handler must be a { } block on one line")
end
T.check("a do block is refused") { gen_error({ "src/a.rb" => APP, "src/c.rb" => controller(".add(\"/x\", get do |a, r| x end)") }).include?("src/c.rb:4: a route handler must be a { } block") }
T.check("an unknown verb is refused") { gen_error({ "src/a.rb" => APP, "src/c.rb" => controller(".add(\"/x\", put { |a, r| x })") }).include?("expected get, post, patch or delete, got put") }
T.check("a block with one parameter is refused") { gen_error({ "src/a.rb" => APP, "src/c.rb" => controller(".add(\"/x\", get { |a| x })") }).include?("takes two parameters") }
T.check("a composed controller without routes is refused") { gen_error({ "src/a.rb" => APP }).include?("src/a.rb:2: no routes found for C.routes") }
T.check("an app without with_default_routes is refused") { gen_error({ "src/c.rb" => controller(".add(\"/x\", get { |a, r| x })") }).include?("no Kilau::AppRoutes.with_default_routes") }
T.check("an inline group in the composition is refused") do
  gen_error({ "src/a.rb" => "class A < Kilau::Hooks\n  def routes = Kilau::AppRoutes.with_default_routes.add(Kilau::Routes.new)\nend\n" }).include?("composes a local or Controller.routes")
end
T.check("routes in a nested class are refused") do
  gen_error({ "src/a.rb" => "module M\n  class C\n    def self.routes\n    end\n  end\nend\n" }).include?("src/a.rb:3: gen routes needs routes declared in a top-level class")
end
T.check("a missing src directory is refused") do
  begin
    KilauTool::RoutesGen.generate("/tmp/kilau-no-app")
    false
  rescue ArgumentError => e
    e.message == "no source directory at /tmp/kilau-no-app/src"
  end
end
