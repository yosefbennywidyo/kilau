# K-045 micro repro: the blog's list page without HTTP or SQLite.
# 100 rows rendered the way examples/blog/build/gen/templates.rb does it
# (`buf << literal`, `buf << escape(x.to_s)`), RENDERS times in one thread.
# Prints the byte total (a checksum) so two compilers can be compared.
module Html
  def self.escape(text)
    text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;").gsub("'", "&#39;")
  end
end

class Post
  attr_reader :id, :title

  def initialize(id, title)
    @id = id
    @title = title
  end
end

def layout(block_title, block_content)
  buf = +""
  buf << "<!doctype html>\n<html lang=\"id\">\n<head><meta charset=\"utf-8\"><title>"
  buf << block_title
  buf << " · Kilau</title></head>\n<body>\n"
  buf << block_content
  buf << "\n</body>\n</html>\n"
  buf
end

def posts_list(posts)
  block_title = +""
  block_title << "Posts"
  block_content = +""
  block_content << "<h1>Posts</h1>\n<p><a href=\"/posts/new\">New post</a></p>\n<ul>\n"
  posts.each do |post|
    block_content << "<li><a href=\"/posts/"
    block_content << Html.escape(post.id.to_s)
    block_content << "\">"
    block_content << Html.escape(post.title.to_s)
    block_content << "</a></li>\n"
  end
  block_content << "</ul>\n"
  layout(block_title, block_content)
end

posts = []
i = 1
while i <= 100
  posts << Post.new(i, "Post number #{i} <with> a title & \"quotes\"")
  i += 1
end

RENDERS = 20_000
total = 0
n = 0
while n < RENDERS
  total += posts_list(posts).bytesize
  n += 1
end
puts total
