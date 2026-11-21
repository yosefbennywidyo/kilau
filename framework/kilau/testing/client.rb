module Kilau
  module Testing
    # Drives a Dispatcher in-process, the way a browser would: forms are
    # urlencoded, and PATCH/DELETE go as POST + _method.
    class Client
      def initialize(hooks, app_context)
        @dispatcher = hooks.serving_dispatcher(app_context)
        @cookies = {}
      end

      def get(path) = perform("GET", path, {})
      def head(path) = perform("HEAD", path, {})
      def options(path) = perform("OPTIONS", path, {})
      def post(path, form) = perform("POST", path, form)

      def patch(path, form)
        fields = { "_method" => "patch" }
        form.each { |name, value| fields[name] = value }
        perform("POST", path, fields)
      end

      def delete(path, form = {})
        fields = { "_method" => "delete" }
        form.each { |name, value| fields[name] = value }
        perform("POST", path, fields)
      end

      private

      def perform(verb, target, form)
        body = Form.encode(form)
        headers = { "host" => "kilau.test" }
        unless body.empty?
          headers["content-type"] = "application/x-www-form-urlencoded"
          headers["content-length"] = body.bytesize.to_s
        end
        jar = @cookies.map { |name, value| "#{name}=#{value}" }.join("; ")
        headers["cookie"] = jar unless jar.empty?
        response = @dispatcher.call(Request.new(verb, target, "HTTP/1.1", headers, body))
        keep_cookies(response)
        response
      end

      # What a browser's jar does with each Set-Cookie line: the first
      # name=value pair is kept, an empty value or Max-Age=0 deletes it.
      def expires_now?(line)
        line.split(";").drop(1).any? { |attribute| attribute.strip.downcase == "max-age=0" }
      end

      def keep_cookies(response)
        response.set_cookies.each do |line|
          pair = line.split(";")[0].to_s
          eq = pair.index("=")
          next if eq.nil? || eq == 0
          name = pair[0, eq].strip
          value = pair[eq + 1, pair.size - eq - 1].strip
          if value.empty? || expires_now?(line)
            @cookies.delete(name)
          else
            @cookies[name] = value
          end
        end
      end
    end
  end
end
