# The Kilau::Page for a request: the signed-in user's email (read from the
# database, not stored in the cookie) and the session's CSRF token. A guest,
# and a session whose user no longer exists, get an empty email.
module PageHelper
  def self.for(app_context, request)
    id = request.session["user_id"]
    return Kilau::Page.for(request) if id.nil? || !id.match?(/\A\d{1,18}\z/)
    user = User.find_by_id(app_context.db, id.to_i)
    return Kilau::Page.for(request) if user.nil?
    Kilau::Page.for(request, user.email)
  end
end
