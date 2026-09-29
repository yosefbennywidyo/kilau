require "kilau"
require_relative "../src/models/posts"
require_relative "../src/views/posts"
T = Kilau::Testing

# Every value a user typed reaches the page escaped, on every view.
hostile = "<script>alert('x')</script> & \"q\""
escaped = "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt; &amp; &quot;q&quot;"
post = Post.new
post.id = 7
post.title = hostile
post.content = hostile

show = Views::Posts.show(post)
print show
T.check("show escapes the title in <title> and <h1>") { show.include?("<title>#{escaped} · Kilau</title>") && show.include?("<h1>#{escaped}</h1>") }
T.check("show escapes the content") { show.include?("<p>#{escaped}</p>") }
T.check("show never holds the raw script") { !show.include?("<script>") }
T.check("the list escapes each title") { Views::Posts.list([post]).include?("<a href=\"/posts/7\">#{escaped}</a>") }
T.check("edit escapes the input value") { Views::Posts.edit(post).include?("value=\"#{escaped}\"") }
T.check("edit posts to the post with a patch override") { Views::Posts.edit(post).include?("<form method=\"post\" action=\"/posts/7\"><input type=\"hidden\" name=\"_method\" value=\"patch\">") }

invalid = Post.new
invalid.title = "<"
invalid.content = ""
invalid.valid?
form = Views::Posts.new_form(invalid)
print form
T.check("errors are listed, escaped") { form.include?("<ul class=\"errors\">") && form.include?("<li>title minimal 2 karakter</li>") }
T.check("the typed value survives, escaped") { form.include?("value=\"&lt;\"") }
T.check("a valid form lists no errors") { !Views::Posts.new_form(Post.new).include?("class=\"errors\"") }
