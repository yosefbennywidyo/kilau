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
T.check("}} inside a string literal does not close an expression") { KilauTool::TemplateLexer.tokenize("{{ \"}}\" + x }}", "t.html", 2).map { |t| t.text } == ["\"}}\" + x"] }
T.check("%} inside a string literal does not close a tag") { KilauTool::TemplateLexer.tokenize("{% if x == '%}' %}", "t.html", 2).map { |t| t.text } == ["if x == '%}'"] }

# A template saved with CRLF line ends: a line holding only a tag still
# leaves no trace, and text keeps the line ends it was written with.
show("a\r\n{% if x %}\r\nb\r\n{% endif %}\r\n")
T.check("{{{ is refused, with the two things it can mean") do
  lex_error("{{{ x }}}") == "t.html:2: {{{ is not a delimiter; write {{ x | safe }} for unescaped output, or {{ {...} }} with a space for a Hash literal"
end
T.check("a Hash literal after a space is still an expression") { KilauTool::TemplateLexer.tokenize("{{ {a: 1}.size }}", "t.html", 2).map { |t| t.text } == ["{a: 1}.size"] }
