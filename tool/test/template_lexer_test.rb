require "kilau"
require_relative "../kilau_tool/template_lexer"
T = Kilau::Testing

def show(body)
  KilauTool::TemplateLexer.tokenize(body, "t.html", 2).each { |token| puts "#{token.line} #{token.kind} #{token.text.inspect}" }
  puts "--"
end

show("<p>{{ post.title }}</p>\n")
show("<ul>\n  {% for x in xs %}\n  <li>{{ x }}</li>\n  {% endfor %}\n</ul>")
show("{# note #}\na {# inline #}b\n")
show("{% if a %}x{% endif %}\n")

def lex_error(body)
  KilauTool::TemplateLexer.tokenize(body, "t.html", 2)
  ""
rescue ArgumentError => e
  e.message
end

T.check("an unclosed {{ names the file and line") { lex_error("a\n{{ x\n}}") == "t.html:3: {{ is not closed by }} on the same line" }
T.check("an empty tag is refused") { lex_error("{%  %}") == "t.html:2: empty {% %}" }
T.check("an empty body has no tokens") { KilauTool::TemplateLexer.tokenize("", "t.html", 2).empty? }
