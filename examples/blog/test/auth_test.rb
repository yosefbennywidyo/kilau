require "kilau"
require_relative "../migration/migrator"
require_relative "../src/app"
require_relative "support/auth_helper"
T = Kilau::Testing
A = AuthHelper

db = Sqlite::Pool.new(":memory:", 1)
db.with { |conn| Kilau::Migrator.new(conn, MIGRATIONS).migrate }
app_context = Kilau::AppContext.new(db, Kilau::Config.parse(A::CONFIG, "test.yaml"), "test")
app = App.new

# The session cookie value a response sets ("" if it sets none).
def session_cookie(response)
  line = response.set_cookies.find { |c| c.start_with?("kilau_session=") }
  line.nil? ? "" : line.split(";")[0].to_s
end

def sign_in(client, email, password) = client.post("/login", { "email" => email, "password" => password, "authenticity_token" => AuthHelper.token(client, "/login") })

# --- the forms ---
anon = Kilau::Testing::Client.new(app, app_context)
login_page = anon.get("/login")
T.check("the sign-in form renders with a token and sets the session cookie") { login_page.status == 200 && login_page.body.include?("action=\"/login\"") && !A.token(anon, "/login").empty? && !session_cookie(login_page).empty? }
T.check("the sign-up form renders with a token") { r = anon.get("/signup"); r.status == 200 && r.body.include?("action=\"/signup\"") && r.body.include?("name=\"authenticity_token\"") }
T.check("a guest's pages offer sign in and sign up") { b = anon.get("/posts").body; b.include?("href=\"/login\"") && b.include?("href=\"/signup\"") && !b.include?("action=\"/logout\"") }

# --- sign-up ---
writer = Kilau::Testing::Client.new(app, app_context)
before_cookie = session_cookie(writer.get("/signup"))
before_token = A.token(writer, "/signup")
signed = A.sign_up(writer, "Writer@X.test", A::PASSWORD)
T.check("a valid sign-up redirects to the posts") { signed.status == 303 && signed.location == "/posts" }
T.check("the sign-up logs the user in") { writer.get("/posts/new").status == 200 }
T.check("the sign-up replaces the session: new cookie and new token (no fixation)") { c = session_cookie(signed); !c.empty? && c != before_cookie && A.token(writer, "/posts/new") != before_token }
T.check("the nav shows the signed-in email") { writer.get("/posts").body.include?("<span class=\"user\">writer@x.test</span>") }
T.check("the nav offers sign out, not sign in") { b = writer.get("/posts").body; b.include?("action=\"/logout\"") && !b.include?("href=\"/login\"") }

other = Kilau::Testing::Client.new(app, app_context)
dup = A.sign_up(other, "  WRITER@x.test ", A::PASSWORD)
T.check("a duplicate address in other case and spacing is a 422, not a 500") { dup.status == 422 && dup.body.include?("email sudah terdaftar") }
T.check("the refused sign-up does not log in") { other.get("/posts/new").status == 303 }
bad = A.sign_up(other, "nobody", A::PASSWORD)
T.check("an invalid address is a 422") { bad.status == 422 && bad.body.include?("email tidak valid") }
short = A.sign_up(other, "short@x.test", "1234567")
T.check("seven characters are refused") { short.status == 422 && short.body.include?("sandi minimal 8 karakter") }
T.check("the refused address stays free") { User.find_by_email(db, "short@x.test").nil? }
T.check("eight characters pass") { A.sign_up(other, "eight@x.test", "12345678").status == 303 }
huge = A.sign_up(Kilau::Testing::Client.new(app, app_context), "huge@x.test", "x" * 1025)
T.check("a 1025-byte password is a 422, refused before hashing") { huge.status == 422 && huge.body.include?("sandi terlalu panjang") && User.find_by_email(db, "huge@x.test").nil? }
T.check("the sign-up form never echoes the password") { !huge.body.include?("xxxxxxxx") }
T.check("a sign-up without a token is a 403") { Kilau::Testing::Client.new(app, app_context).post("/signup", { "email" => "t@x.test", "password" => A::PASSWORD }).status == 403 }

# --- sign-in ---
visitor = Kilau::Testing::Client.new(app, app_context)
pre_cookie = session_cookie(visitor.get("/login"))
pre_token = A.token(visitor, "/login")
wrong = sign_in(visitor, "writer@x.test", "wrong horse")
ghost = sign_in(visitor, "ghost@x.test", "wrong horse")
T.check("a wrong password is a 422 with the one message") { wrong.status == 422 && wrong.body.include?("<li>email atau sandi salah</li>") }
T.check("an unknown address is the same 422 and message") { ghost.status == 422 && ghost.body.include?("<li>email atau sandi salah</li>") }
T.check("the two responses are identical apart from the echoed address") { wrong.body.gsub("writer@x.test", "E") == ghost.body.gsub("ghost@x.test", "E") && wrong.headers["content-type"] == ghost.headers["content-type"] }
T.check("neither response logs in") { visitor.get("/posts/new").status == 303 }
T.check("the form never echoes the password") { !wrong.body.include?("wrong horse") }
T.check("a sign-in without a token is a 403") { Kilau::Testing::Client.new(app, app_context).post("/login", { "email" => "writer@x.test", "password" => A::PASSWORD }).status == 403 }
good = sign_in(visitor, " WRITER@x.test", A::PASSWORD)
T.check("the right password redirects to the posts") { good.status == 303 && good.location == "/posts" }
T.check("the user is logged in after it") { visitor.get("/posts/new").status == 200 }
T.check("the session cookie changes at login (no fixation)") { c = session_cookie(good); !c.empty? && c != pre_cookie }
T.check("the CSRF token changes at login") { t = A.token(visitor, "/posts/new"); !t.empty? && t != pre_token }

# --- sign-out ---
out_token = A.token(visitor, "/posts")
T.check("a sign-out without a token is a 403 and keeps the session") { visitor.post("/logout", {}).status == 403 && visitor.get("/posts/new").status == 200 }
bye = visitor.post("/logout", { "authenticity_token" => out_token })
T.check("sign-out redirects to the root") { bye.status == 303 && bye.location == "/" }
T.check("sign-out empties the session") { visitor.get("/posts/new").status == 303 }
T.check("the old token is dead after sign-out") { visitor.post("/posts", { "authenticity_token" => out_token, "post[title]" => "Halo", "post[content]" => "x" }).status == 403 }

# --- the blog is protected ---
guest = Kilau::Testing::Client.new(app, app_context)
tok = A.token(guest, "/login")
T.check("a guest's new form is a redirect to /login") { r = guest.get("/posts/new"); r.status == 303 && r.location == "/login" }
T.check("a guest's edit form is a redirect to /login") { r = guest.get("/posts/1/edit"); r.status == 303 && r.location == "/login" }
T.check("a guest's POST /posts is a redirect to /login") { r = guest.post("/posts", { "authenticity_token" => tok, "post[title]" => "Halo", "post[content]" => "x" }); r.status == 303 && r.location == "/login" }
T.check("a guest's PATCH is a redirect to /login, before any lookup") { r = guest.patch("/posts/1", { "authenticity_token" => tok, "post[title]" => "Halo", "post[content]" => "x" }); r.status == 303 && r.location == "/login" }
T.check("a guest's DELETE is a redirect to /login, before any lookup") { r = guest.delete("/posts/1", { "authenticity_token" => tok }); r.status == 303 && r.location == "/login" }
T.check("a POST without a token is a 403, not a redirect") { guest.post("/posts", { "post[title]" => "Halo", "post[content]" => "x" }).status == 403 }
T.check("nothing was written by a guest") { Post.all(db).empty? }

wtok = A.token(writer, "/posts/new")
made = writer.post("/posts", { "authenticity_token" => wtok, "post[title]" => "Halo", "post[content]" => "Isi" })
T.check("a signed-in user can create a post") { made.status == 303 && made.location == "/posts/1" }
T.check("a guest can read the list") { r = guest.get("/posts"); r.status == 200 && r.body.include?("Halo") }
T.check("a guest can read a post") { r = guest.get("/posts/1"); r.status == 200 && r.body.include?("<h1>Halo</h1>") }

# --- every form carries the token ---
def forms_carry_token?(body)
  opened = body.scan("<form").size
  opened > 0 && body.scan("name=\"authenticity_token\"").size >= opened
end
T.check("every form on every page carries the token") do
  ["/login", "/signup"].all? { |p| forms_carry_token?(guest.get(p).body) } &&
    ["/posts/new", "/posts/1/edit", "/posts/1", "/posts"].all? { |p| forms_carry_token?(writer.get(p).body) }
end

# --- escaping ---
amp = Kilau::Testing::Client.new(app, app_context)
T.check("an address with an HTML-special character signs up") { A.sign_up(amp, "a&b@x.test", A::PASSWORD).status == 303 }
shown = amp.get("/posts").body
T.check("it is escaped in the nav") { shown.include?("<span class=\"user\">a&amp;b@x.test</span>") && !shown.include?("a&b@x.test") }
# The validation is loose (one @, no whitespace), so a tag-shaped address is accepted; the page must still escape it.
tag = Kilau::Testing::Client.new(app, app_context)
T.check("a tag-shaped address signs up") { A.sign_up(tag, "<script>@x.test", A::PASSWORD).status == 303 }
tagged = tag.get("/posts").body
T.check("it is escaped in the nav and never raw") { tagged.include?("<span class=\"user\">&lt;script&gt;@x.test</span>") && !tagged.include?("<script>") }
echo = A.sign_up(Kilau::Testing::Client.new(app, app_context), "<b>@x.test", "short")
T.check("a re-rendered sign-up escapes what was typed") { echo.status == 422 && echo.body.include?("value=\"&lt;b&gt;@x.test\"") && !echo.body.include?("<b>") }
db.close
