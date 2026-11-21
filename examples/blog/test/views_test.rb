require "kilau"
require_relative "../src/models/posts"
require_relative "../src/views/posts"
require_relative "../src/views/sessions"
require_relative "../src/views/users"
T = Kilau::Testing

# Every value a user typed reaches the page escaped, on every view.
hostile = "<script>alert('x')</script> & \"q\""
escaped = "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt; &amp; &quot;q&quot;"
guest = Kilau::Page.new("", "tok123")
post = Post.new
post.id = 7
post.title = hostile
post.content = hostile

show = Views::Posts.show(post, guest)
print show
T.check("show escapes the title in <title> and <h1>") { show.include?("<title>#{escaped} · Kilau</title>") && show.include?("<h1>#{escaped}</h1>") }
T.check("show escapes the content") { show.include?("<p>#{escaped}</p>") }
T.check("show never holds the raw script") { !show.include?("<script>") }
T.check("the list escapes each title") { Views::Posts.list([post], guest).include?("<a href=\"/posts/7\">#{escaped}</a>") }
T.check("edit escapes the input value") { Views::Posts.edit(post, guest).include?("value=\"#{escaped}\"") }
T.check("edit posts to the post with a patch override") { Views::Posts.edit(post, guest).include?("<form method=\"post\" action=\"/posts/7\"><input type=\"hidden\" name=\"_method\" value=\"patch\">") }

invalid = Post.new
invalid.title = "<"
invalid.content = ""
invalid.valid?
form = Views::Posts.new_form(invalid, guest)
print form
T.check("errors are listed, escaped") { form.include?("<ul class=\"errors\">") && form.include?("<li>title minimal 2 karakter</li>") }
T.check("the typed value survives, escaped") { form.include?("value=\"&lt;\"") }
T.check("a valid form lists no errors") { !Views::Posts.new_form(Post.new, guest).include?("class=\"errors\"") }

# The token reaches every form, after the _method override where there is one.
token_field = "<input type=\"hidden\" name=\"authenticity_token\" value=\"tok123\">"
T.check("edit carries the token after the method override") { Views::Posts.edit(post, guest).include?("<input type=\"hidden\" name=\"_method\" value=\"patch\">#{token_field}") }
T.check("the delete form carries the token") { show.include?("<input type=\"hidden\" name=\"_method\" value=\"delete\">#{token_field}") }
T.check("the new form carries the token") { form.include?("<form method=\"post\" action=\"/posts\">#{token_field}") }
T.check("the sign-in form carries the token") { Views::Sessions.new_form("", [], guest).include?("<form method=\"post\" action=\"/login\">#{token_field}") }
T.check("the sign-up form carries the token") { Views::Users.new_form("", [], guest).include?("<form method=\"post\" action=\"/signup\">#{token_field}") }

# The nav: a guest is offered sign in and sign up; a user sees their email, escaped, and a sign-out form.
member = Kilau::Page.new("a&b@x.test", "tok123")
T.check("a guest's nav links to sign in and sign up") { show.include?("<a href=\"/login\">") && show.include?("<a href=\"/signup\">") && !show.include?("/logout") }
member_view = Views::Posts.list([post], member)
T.check("a signed-in nav shows the email escaped") { member_view.include?("<span class=\"user\">a&amp;b@x.test</span>") && !member_view.include?("a&b@x.test") }
T.check("a signed-in nav has a sign-out form with the token") { member_view.include?("<form method=\"post\" action=\"/logout\">#{token_field}") && !member_view.include?("/login") }
T.check("a hostile email is escaped in the nav") { Views::Posts.list([post], Kilau::Page.new("<script>x</script>@x.test", "t")).include?("&lt;script&gt;x&lt;/script&gt;@x.test") }
T.check("the sign-in form echoes the typed email escaped, never a password") { v = Views::Sessions.new_form("\"><b>@x.test", ["email atau sandi salah"], guest); v.include?("value=\"&quot;&gt;&lt;b&gt;@x.test\"") && v.include?("<li>email atau sandi salah</li>") && !v.include?("<b>") }
