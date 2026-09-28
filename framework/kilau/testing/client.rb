module Kilau
  module Testing
    # Drives a Dispatcher in-process, the way a browser would: forms are
    # urlencoded, and PATCH/DELETE go as POST + _method.
    class Client
      def initialize(hooks, app_context)
        @dispatcher = Dispatcher.new(hooks.routes, app_context)
      end

      def get(path) = perform("GET", path, {})
      def post(path, form) = perform("POST", path, form)

      def patch(path, form)
        fields = { "_method" => "patch" }
        form.each { |name, value| fields[name] = value }
        perform("POST", path, fields)
      end

      def delete(path) = perform("POST", path, { "_method" => "delete" })

      private

      def perform(verb, target, form)
        body = Form.encode(form)
        headers = { "host" => "kilau.test" }
        unless body.empty?
          headers["content-type"] = "application/x-www-form-urlencoded"
          headers["content-length"] = body.bytesize.to_s
        end
        @dispatcher.call(Request.new(verb, target, "HTTP/1.1", headers, body))
      end
    end
  end
end
