module Kilau
  # One HTTP verb bound to a handler block (Loco's get(handler)).
  class Endpoint
    attr_reader :verb

    def initialize(verb, handler)
      @verb = verb
      @handler = handler
    end

    def call(app_context, request) = @handler.call(app_context, request)
  end

  # Base for an app's controllers. Handlers are class methods; routes bind
  # them with blocks, so dispatch needs no method name at run time.
  class Controller
    def self.get(&handler) = Endpoint.new("GET", handler)
    def self.post(&handler) = Endpoint.new("POST", handler)
    def self.patch(&handler) = Endpoint.new("PATCH", handler)
    def self.delete(&handler) = Endpoint.new("DELETE", handler)
  end
end
