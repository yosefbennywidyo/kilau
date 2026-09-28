# Views for posts (spec §4.4). Until templates land (plan 3), each view
# builds its HTML here; plan 3 swaps every body for a Templates.posts_*
# call and keeps these signatures.
module Views
  module Posts
    def self.list(posts)
      items = posts.map { |post| "<li><a href=\"/posts/#{post.id}\">#{h(post.title)}</a></li>" }.join("\n")
      layout("Posts", "<h1>Posts</h1>\n<p><a href=\"/posts/new\">New post</a></p>\n<ul>\n#{items}\n</ul>")
    end

    def self.show(post)
      layout(post.title.to_s, "<h1>#{h(post.title)}</h1>\n<p>#{h(post.content)}</p>\n" \
        "<p><a href=\"/posts/#{post.id}/edit\">Edit</a></p>\n" \
        "<form method=\"post\" action=\"/posts/#{post.id}\"><input type=\"hidden\" name=\"_method\" value=\"delete\"><button>Delete</button></form>\n" \
        "<p><a href=\"/posts\">All posts</a></p>")
    end

    def self.new_form(post) = layout("New post", "<h1>New post</h1>\n#{form(post, "/posts", "")}")

    def self.edit(post)
      override = "<input type=\"hidden\" name=\"_method\" value=\"patch\">"
      layout("Edit post", "<h1>Edit post</h1>\n#{form(post, "/posts/#{post.id}", override)}")
    end

    def self.form(post, action, override)
      "<form method=\"post\" action=\"#{action}\">#{override}\n#{error_list(post)}" \
        "<p><label>Title <input name=\"post[title]\" value=\"#{h(post.title)}\"></label></p>\n" \
        "<p><label>Content <textarea name=\"post[content]\">#{h(post.content)}</textarea></label></p>\n" \
        "<button>Save</button>\n</form>"
    end

    def self.error_list(post)
      return "" if post.errors.empty?
      items = []
      post.errors.each { |field, message| items << "<li>#{h(field)} #{h(message)}</li>" }
      "<ul class=\"errors\">#{items.join}</ul>\n"
    end

    def self.layout(title, body)
      "<!doctype html>\n<html lang=\"id\">\n<head><meta charset=\"utf-8\"><title>#{h(title)} · Kilau</title></head>\n<body>\n#{body}\n</body>\n</html>\n"
    end

    def self.h(value) = Kilau::Html.escape(value.to_s)
  end
end
