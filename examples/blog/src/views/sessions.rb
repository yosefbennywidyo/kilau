require_relative "../../build/gen/templates"

module Views
  module Sessions
    def self.new_form(email, errors, page) = Templates.sessions_new(email, errors, page)
  end
end
