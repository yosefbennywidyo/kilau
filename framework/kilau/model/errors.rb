module Kilau
  # Validation messages by field name. A second message on the same field
  # is appended, so a form can show every problem at once.
  class Errors
    def initialize
      @messages = {}
    end

    def add(field, message)
      existing = @messages[field]
      @messages[field] = existing.nil? ? message : "#{existing}, #{message}"
      nil
    end

    def [](field) = @messages[field]
    def empty? = @messages.empty?
    def size = @messages.size

    def each
      @messages.each { |field, message| yield field, message }
      nil
    end

    def clear
      @messages.clear
      nil
    end
  end
end
