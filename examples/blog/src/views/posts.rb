require_relative "../../build/gen/templates"

# Views for posts (spec §4.4): each renders its template from
# assets/views/posts, compiled by `kilau gen templates` (make templates).
# Every view takes the Kilau::Page last: the layout's nav and the forms'
# CSRF token come from it.
module Views
  module Posts
    def self.list(posts, page) = Templates.posts_list(posts, page)
    def self.show(post, page) = Templates.posts_show(post, page)
    def self.new_form(post, page) = Templates.posts_new(post, page)
    def self.edit(post, page) = Templates.posts_edit(post, page)
  end
end
