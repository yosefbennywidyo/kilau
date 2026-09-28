# K-011: URI.decode_www_form_component decodes malformed input silently in
# Spinel ("%zz" -> NUL byte, "%4" kept) where CRuby raises ArgumentError.
require "uri"
["%zz", "post%5Bt%zz", "%4", "a%2", "%C3%A9", "%FF"].each do |s|
  begin
    puts "#{s.inspect} -> #{URI.decode_www_form_component(s).inspect}"
  rescue ArgumentError => e
    puts "#{s.inspect} -> ArgumentError #{e.message}"
  end
end
