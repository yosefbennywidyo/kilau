require "kilau"
T = Kilau::Testing

SAMPLE = <<~YAML
  # Kilau development config
  server:
    host: "127.0.0.1"
    port: 3000   # KILAU_SERVER_PORT overrides
  database:
    path: db/development.sqlite3
    pool: 4
  logger:
    requests: true
  labels:
    motto: "kilau # bukan komentar"
    code: "42"
YAML

def config_error(text)
  Kilau::Config.parse(text, "t.yaml")
  "no error"
rescue Kilau::Config::Error => e
  e.message
end

def getter_error
  yield
  "no error"
rescue Kilau::Config::Error => e
  e.message
end

config = Kilau::Config.parse(SAMPLE, "t.yaml")
T.check("a quoted string reads without its quotes") { config.string("server.host") == "127.0.0.1" }
T.check("an integer reads as Integer") { config.int("server.port") == 3000 }
T.check("a plain string reads as written") { config.string("database.path") == "db/development.sqlite3" }
T.check("a nested integer reads") { config.int("database.pool") == 4 }
T.check("a boolean reads") { config.bool("logger.requests") == true }
T.check("a # inside quotes is not a comment") { config.string("labels.motto") == "kilau # bukan komentar" }
T.check("key? sees leaves only") { config.key?("server.port") && !config.key?("server") && !config.key?("nope") }

T.check("a list is refused with its line") { config_error("a:\n  - x\n") == "t.yaml:2: lists are not supported" }
T.check("an anchor is refused") { config_error("a: &x 1\n") == "t.yaml:1: values starting with & are not supported" }
T.check("a block scalar is refused") { config_error("a: |\n  text\n") == "t.yaml:1: values starting with | are not supported" }
T.check("a flow collection is refused") { config_error("a: [1, 2]\n") == "t.yaml:1: values starting with [ are not supported" }
T.check("a single-quoted string is refused") { config_error("a: 'x'\n") == "t.yaml:1: values starting with ' are not supported" }
T.check("a tab in the indentation is refused") { config_error("a:\n\tb: 1\n") == "t.yaml:2: tabs are not allowed for indentation" }
T.check("a duplicate key is refused") { config_error("a: 1\na: 2\n") == "t.yaml:2: duplicate key a" }
T.check("a map key without children is refused") { config_error("a:\nb: 1\n") == "t.yaml:1: a has no value" }
T.check("a map key at the end of the file is refused") { config_error("a: 1\nb:\n") == "t.yaml:2: b has no value" }
T.check("an indented line under a scalar is refused") { config_error("a: 1\n  b: 2\n") == "t.yaml:2: indentation does not match any open map" }
T.check("an unterminated quote is refused") { config_error("a: \"open\n") == "t.yaml:1: unterminated or embedded double quote" }
T.check("a line without a key is refused") { config_error("just text\n") == "t.yaml:1: expected `key: value` or `key:`" }
T.check("a missing space after the colon is refused") { config_error("a:1\n") == "t.yaml:1: expected a space after `:`" }

T.check("a non-integer read as int names the key") { getter_error { config.int("database.path") } == "t.yaml: database.path must be an integer, got \"db/development.sqlite3\"" }
T.check("a quoted number is a string, not an int") { getter_error { config.int("labels.code") } == "t.yaml: labels.code must be an integer, got \"42\"" }
T.check("a non-boolean read as bool names the key") { getter_error { config.bool("server.port") } == "t.yaml: server.port must be true or false, got \"3000\"" }
T.check("a missing key names the key") { getter_error { config.string("nope.x") } == "t.yaml: missing key nope.x" }
T.check("load of a missing file names the path") { getter_error { Kilau::Config.load("/nonexistent-kilau.yaml") } == "config: no file at /nonexistent-kilau.yaml" }

ENV["KILAU_SERVER_PORT"] = "4000"
T.check("KILAU_SERVER_PORT overrides server.port") { config.int("server.port") == 4000 }
