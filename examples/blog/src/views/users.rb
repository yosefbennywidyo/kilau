require_relative "../../build/gen/templates"

module Views
  module Users
    def self.new_form(email, errors, page) = Templates.users_new(email, errors, page)
  end
end
