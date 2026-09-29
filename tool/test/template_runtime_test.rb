require "kilau"
require_relative "fixtures/templates"
T = Kilau::Testing

# Runs the committed output of template_generate_test.rb, compiled like any
# app's templates.
print Templates.items_list(["<a>", "b & c"], "<i>")
print Templates.items_list(["z"], "long")
print Templates.pairs({ "title" => "<x>", "body" => "ok" })
print Templates.plain

T.check("an expression is escaped") { Templates.items__item("<b>\"'&") == "<li>&lt;b&gt;&quot;&#39;&amp;</li>\n" }
T.check("| safe is not escaped") { Templates.items_list(["z"], "<i>").include?("<p>&lt;i&gt; | <i></p>") }
T.check("elif takes its branch") { Templates.items_list(["z"], "x").include?("<p>x | x</p>") }
T.check("if takes its branch") { Templates.items_list(["z"], "").include?("<p>none</p>") }
T.check("a filled block replaces the layout default") { Templates.items_list(["z"], "").include?("<title>Items</title>") }
T.check("an unfilled block keeps the layout default") { Templates.plain.include?("<title>Kilau</title>") }
T.check("text holding \#{ stays literal") { Templates.items_list(["z"], "long").include?("<p class=\"n\">\#{raw} 4</p>") }
