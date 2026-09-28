module Kilau
  # One parsed HTTP request. Every raw value is a String; conversions are
  # explicit (path_int) so the params stay Hash[String, String].
  # request_method, not method: a `method` reader would shadow Object#method.
  class Request
    attr_reader :request_method, :path, :query_string, :http_version, :headers, :body
    attr_accessor :path_params

    def initialize(request_method, target, http_version, headers, body)
      @request_method = request_method
      q = target.index("?")
      @path = q.nil? ? target : target[0, q]
      @query_string = q.nil? ? "" : target[q + 1, target.size - q - 1]
      @http_version = http_version
      @headers = headers
      @body = body
      @path_params = {}
      @form_values = nil
      @query_values = nil
    end

    def header(name) = @headers[name.downcase]

    # At most 18 digits, so the value always fits an Integer.
    def path_int(name)
      raw = @path_params[name]
      if raw.nil? || !raw.match?(/\A\d{1,18}\z/)
        raise Kilau::Error::BadRequest, "#{name} must be a whole number"
      end
      raw.to_i
    end

    def query(name) = query_values[name]
    def form_value(name) = form_values[name]

    # The fields of a Rails-style nested form group: form("post") reads
    # post[title] and post[content] as "title" and "content".
    def form(prefix)
      out = {}
      head = prefix + "["
      form_values.each do |name, value|
        if name.start_with?(head) && name.end_with?("]") && name.size > head.size + 1
          out[name[head.size, name.size - head.size - 1]] = value
        end
      end
      out
    end

    def override_method(verb)
      @request_method = verb
      nil
    end

    private

    def form_values
      if @form_values.nil?
        type = header("content-type").to_s
        @form_values = type.start_with?("application/x-www-form-urlencoded") ? Form.decode(@body) : {}
      end
      @form_values
    end

    def query_values
      @query_values = Form.decode(@query_string) if @query_values.nil?
      @query_values
    end
  end
end
