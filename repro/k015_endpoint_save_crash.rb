# K-015: a Post saved from a handler reached through Endpoint#call segfaults
# in Spinel: the created_at Integer in the mixed binds array is read back as
# a String and passed to String#include?. CRuby prints 303.
#
# Not standalone: it needs the blog app as of commit 6ff14c7 + the plan-2
# Task 7 files. Run from examples/blog:
#   cp ../../repro/k015_endpoint_save_crash.rb test/zz_k015.rb
#   spinel $(cd ../../framework && spin flags) test/zz_k015.rb -o /tmp/k015; /tmp/k015; echo $?   # 139
#   rm test/zz_k015.rb
# Reductions that do NOT crash: calling PostsController.add directly; saving
# inside a plain stored proc; a framework-free copy of the same call chain.
require "kilau"
require_relative "../migration/migrator"
require_relative "../src/app"
db = Kilau::DB::Pool.new(":memory:", 1)
db.with { |conn| Kilau::Migrator.new(conn, MIGRATIONS).migrate }
app_context = Kilau::AppContext.new(db, Kilau::Config.parse("app:\n  name: blog\n", "test.yaml"), "test")
body = "post%5Btitle%5D=Halo&post%5Bcontent%5D=Isi"
req = Kilau::Request.new("POST", "/posts", "HTTP/1.1", { "content-type" => "application/x-www-form-urlencoded" }, body)
puts PostsController.routes.routes[1].endpoint.call(app_context, req).status
