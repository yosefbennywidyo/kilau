module Kilau
  module Html
    def self.escape(text)
      text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;").gsub("'", "&#39;")
    end
  end
end
