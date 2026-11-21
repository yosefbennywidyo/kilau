require "kilau"
T = Kilau::Testing

page = Kilau::Page.new("a@x.test", "tok")
T.check("a page keeps the email and the token") { page.user_email == "a@x.test" && page.token == "tok" }
T.check("the layout defaults to web") { page.layout == "web" }
T.check("Page.new(a, b).layout is web") { Kilau::Page.new("a", "b").layout == "web" }
T.check("a page with an email is signed in") { page.signed_in? }
T.check("a page with an empty email is a guest") { !Kilau::Page.new("", "tok").signed_in? }
T.check("a layout can be named") { Kilau::Page.new("", "t", "admin").layout == "admin" }

request = Kilau::Request.new("GET", "/", "HTTP/1.1", {}, "")
request.session = Kilau::Session.new("page-test-secret")
guest = Kilau::Page.for(request)
T.check("Page.for(request).layout is web") { guest.layout == "web" }
T.check("Page.for defaults to a guest") { !guest.signed_in? && guest.user_email == "" }
T.check("Page.for carries the session's CSRF token") { !guest.token.empty? && guest.token == Kilau::Csrf.token(request.session) }
bare = Kilau::Request.new("GET", "/", "HTTP/1.1", {}, "")
message = ""
begin
  Kilau::Page.for(bare)
rescue ArgumentError => e
  message = e.message
end
T.check("Page.for without sessions says so instead of a nil error") { message.include?("needs sessions") }
member = Kilau::Page.for(request, "m@x.test")
T.check("Page.for takes the email it is given") { member.signed_in? && member.user_email == "m@x.test" && member.token == guest.token }
