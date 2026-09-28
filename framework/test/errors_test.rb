require "kilau"
T = Kilau::Testing

errors = Kilau::Errors.new
T.check("new errors are empty") { errors.empty? && errors.size == 0 }
errors.add("title", "is too short")
errors.add("title", "is required")
errors.add("body", "is required")
T.check("messages on one field are joined") { errors["title"] == "is too short, is required" }
T.check("a field without errors reads nil") { errors["nope"].nil? }
T.check("size counts fields") { errors.size == 2 }
seen = []
errors.each { |field, message| seen << field }
T.check("each yields fields in insertion order") { seen == ["title", "body"] }
errors.clear
T.check("clear empties") { errors.empty? }
