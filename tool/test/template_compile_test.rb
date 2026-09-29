require "kilau"
require_relative "../kilau_tool/template_compile"
T = Kilau::Testing

def parse(path, source) = KilauTool::Template.parse(path, source)

# The message of the ArgumentError that compiling these sources raises,
# or "" when they compile. sources: path => source, compiled in path order.
def compile_error(sources)
  templates = []
  sources.keys.sort.each { |path| templates << parse(path, sources[path]) }
  KilauTool::TemplateCompile.render(templates)
  ""
rescue ArgumentError => e
  e.message
end



T.check("a nested path becomes a method name") { parse("posts/_form.html", "{#- args: post -#}\n").method_name == "posts__form" }
T.check("args are read from the first line") { parse("a.html", "{#- args: post, flash -#}\n").args == ["post", "flash"] }
T.check("filter_of finds safe") { KilauTool::TemplateCompile.filter_of("x.body | safe") == "safe" }
T.check("|| is not a filter") { KilauTool::TemplateCompile.filter_of("a || b") == "" }
T.check("free identifiers skip methods, constants, keys and strings") do
  KilauTool::TemplateCompile.free_identifiers("post.title + Kilau::X.y(k: \"z w\", n) if nil") == ["post", "n"]
end

T.check("a missing args line is refused") { compile_error({ "a.html" => "<p>hi</p>\n" }).include?("a.html:1: the first line must be") }
T.check("an undeclared variable is refused with its line") { compile_error({ "a.html" => "{#- args: post -#}\n<p>\n{{ pots.title }}</p>\n" }).include?("a.html:3: pots is not an argument") }
T.check("a loop variable leaves scope at endfor") { compile_error({ "a.html" => "{#- args: xs -#}\n{% for x in xs %}{% endfor %}{{ x }}\n" }).include?("a.html:2: x is not an argument") }
T.check("an unknown filter is refused") { compile_error({ "a.html" => "{#- args: x -#}\n{{ x | upper }}\n" }).include?("unknown filter upper") }
T.check("an unclosed if names its line") { compile_error({ "a.html" => "{#- args: x -#}\n\n{% if x %}\n" }).include?("a.html:3: {% if %} is never closed") }
T.check("an unclosed delimiter is refused") { compile_error({ "a.html" => "{#- args: x -#}\n{{ x\n}}\n" }).include?("a.html:2: {{ is not closed") }
T.check("an unknown tag is refused") { compile_error({ "a.html" => "{#- args: -#}\n{% while x %}\n" }).include?("unknown tag {% while %}") }
T.check("a missing include target is refused") { compile_error({ "a.html" => "{#- args: -#}\n{% include \"b.html\" %}\n" }).include?("a.html:2: no template b.html") }
T.check("an include needs its args in scope") do
  compile_error({ "a.html" => "{#- args: -#}\n{% include \"b.html\" %}\n", "b.html" => "{#- args: post -#}\n" }).include?("b.html needs post")
end
T.check("an include cycle is refused") do
  compile_error({ "a.html" => "{#- args: -#}\n{% include \"b.html\" %}\n", "b.html" => "{#- args: -#}\n{% include \"a.html\" %}\n" }).include?("template cycle: a.html -> b.html -> a.html")
end
T.check("text outside a block of a child is refused") do
  compile_error({ "l.html" => "{#- args: -#}\n{% block a %}{% endblock %}\n", "c.html" => "{#- args: -#}\n{% extends \"l.html\" %}\nstray\n" }).include?("c.html:3: text outside {% block %}")
end
T.check("a child block the layout lacks is refused") do
  compile_error({ "l.html" => "{#- args: -#}\n{% block a %}{% endblock %}\n", "c.html" => "{#- args: -#}\n{% extends \"l.html\" %}\n{% block b %}{% endblock %}\n" }).include?("l.html has no {% block b %}")
end
T.check("extends after other content is refused") do
  compile_error({ "l.html" => "{#- args: -#}\n", "c.html" => "{#- args: -#}\n<p>\n{% extends \"l.html\" %}\n" }).include?("c.html:3: {% extends %} must be the first tag")
end
T.check("two templates with one method name are refused") do
  compile_error({ "a/b.html" => "{#- args: -#}\n", "a_b.html" => "{#- args: -#}\n" }).include?("both compile to Templates.a_b")
end
T.check("buf is reserved") { compile_error({ "a.html" => "{#- args: buf -#}\n" }).include?("buf is reserved") }
T.check("a loop variable may not shadow an argument") do
  compile_error({ "a.html" => "{#- args: post, posts -#}\n{% for post in posts %}{% endfor %}\n" }).include?("shadows")
end
