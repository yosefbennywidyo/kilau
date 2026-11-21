require "kilau"
require_relative "../migration/migrator"
require_relative "../src/models/users"
T = Kilau::Testing

db = Sqlite::Pool.new(":memory:", 1)
db.with { |conn| Kilau::Migrator.new(conn, MIGRATIONS).migrate }

T.check("normalize_email strips and downcases") { User.normalize_email("  Ana@Example.TEST \n") == "ana@example.test" }
T.check("a plain address is valid") { User.valid_email?("ana@example.test") }
T.check("an empty address is not valid") { !User.valid_email?("") }
T.check("no @ is not valid") { !User.valid_email?("ana.example.test") }
T.check("two @ are not valid") { !User.valid_email?("a@b@c.test") }
T.check("an empty local part is not valid") { !User.valid_email?("@example.test") }
T.check("an empty domain is not valid") { !User.valid_email?("ana@") }
T.check("whitespace inside is not valid") { !User.valid_email?("an a@example.test") }
long_local = "a" * 247
T.check("254 characters is valid, 255 is not") { User.valid_email?(long_local + "@x.test") && !User.valid_email?(long_local + "b@x.test") }

user, errors = User.register(db, "  Ana@Example.TEST ", "correct horse")
T.check("a valid registration returns the user and no errors") { !user.nil? && errors.empty? }
T.check("the email is stored normalized") { user.email == "ana@example.test" }
T.check("the digest is a pbkdf2 digest, not the password") { user.password_digest.start_with?("pbkdf2$sha256$") && !user.password_digest.include?("correct horse") }
T.check("find_by_email finds it") { User.find_by_email(db, "ana@example.test").id == user.id }
T.check("find_by_email of another address is nil") { User.find_by_email(db, "nobody@example.test").nil? }
T.check("authenticate? accepts the password") { user.authenticate?("correct horse") }
T.check("authenticate? refuses another") { !user.authenticate?("wrong horse") }

dup_user, dup_errors = User.register(db, " ANA@example.test", "correct horse")
T.check("the same address in other case and spacing is refused") { dup_user.nil? && dup_errors == ["email sudah terdaftar"] }
T.check("the database refuses a duplicate that slipped past the lookup") { User.create(db, "ana@example.test", Kilau::Password.digest("x" * 8, 1000)).nil? }
T.check("create works for a new address") { !User.create(db, "bo@example.test", Kilau::Password.digest("x" * 8, 1000)).nil? }

bad_user, bad_errors = User.register(db, "not an email", "short")
T.check("an invalid email and a short password are both reported") { bad_user.nil? && bad_errors == ["email tidak valid", "sandi minimal 8 karakter"] }
T.check("seven characters are too short") { User.register(db, "c@example.test", "1234567")[1] == ["sandi minimal 8 karakter"] }
T.check("eight characters pass") { !User.register(db, "c@example.test", "12345678")[0].nil? }
T.check("the minimum counts characters, not bytes") { User.register(db, "d@example.test", "ééééééé")[1] == ["sandi minimal 8 karakter"] }
T.check("eight multibyte characters pass") { !User.register(db, "d@example.test", "éééééééé")[0].nil? }
over = "x" * (Kilau::Password::MAX_BYTES + 1)
T.check("a password over the byte cap is refused") { User.register(db, "e@example.test", over)[1] == ["sandi terlalu panjang"] }
T.check("it is refused before any row is written") { User.find_by_email(db, "e@example.test").nil? }
db.close
