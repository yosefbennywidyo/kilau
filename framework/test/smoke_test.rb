require "kilau"
T = Kilau::Testing

T.check("kilau loads") { Kilau::VERSION == "0.1.0" }
