class HealthController < ActionController::Base
  def ping = render(plain: "{\"ok\":true}", content_type: "application/json")
end
