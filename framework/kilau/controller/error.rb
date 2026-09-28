module Kilau
  # An error a handler raises to answer with an HTTP status. The status is
  # an ivar set through initialize: a subclass overriding a status method
  # does not compile once rescued as Kilau::Error (docs/CATALOG.md K-010).
  class Error < StandardError
    attr_reader :status

    def initialize(status, message)
      super(message)
      @status = status
    end

    class NotFound < Error
      def initialize(message = "not found") = super(404, message)
    end

    class BadRequest < Error
      def initialize(message = "bad request") = super(400, message)
    end

    class Unauthorized < Error
      def initialize(message = "unauthorized") = super(401, message)
    end
  end
end
