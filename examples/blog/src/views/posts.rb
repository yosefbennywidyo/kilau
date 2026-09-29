require_relative "../../build/gen/templates"

# Views for posts (spec §4.4): each renders its template from
# assets/views/posts, compiled by `kilau gen templates` (make templates).
module Views
  module Posts
    def self.list(posts) = Templates.posts_list(posts)
    def self.show(post) = Templates.posts_show(post)
    def self.new_form(post) = Templates.posts_new(post)
    def self.edit(post) = Templates.posts_edit(post)
  end
end
