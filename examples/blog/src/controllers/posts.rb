class PostParams
  attr_reader :title, :content

  def self.from_form(fields) = new(fields.fetch("title", ""), fields.fetch("content", ""))

  def initialize(title, content)
    @title = title
    @content = content
  end

  def apply(post)
    post.title = @title
    post.content = @content
  end
end

class PostsController < Kilau::Controller
  def self.routes
    Kilau::Routes.new.prefix("posts")
      .add("/", get { |app_context, request| list(app_context, request) })
      .add("/", post { |app_context, request| add(app_context, request) })
      .add("/new", get { |app_context, request| new_form(app_context, request) })
      .add("/:id", get { |app_context, request| show(app_context, request) })
      .add("/:id/edit", get { |app_context, request| edit(app_context, request) })
      .add("/:id", patch { |app_context, request| update(app_context, request) })
      .add("/:id", delete { |app_context, request| remove(app_context, request) })
  end

  def self.load_item(app_context, request)
    post = Post.find_by_id(app_context.db, request.path_int("id"))
    raise Kilau::Error::NotFound, "post not found" if post.nil?
    post
  end

  def self.list(app_context, request) = Kilau::Format.render(Views::Posts.list(Post.all(app_context.db)))
  def self.new_form(app_context, request) = Kilau::Format.render(Views::Posts.new_form(Post.new))
  def self.show(app_context, request) = Kilau::Format.render(Views::Posts.show(load_item(app_context, request)))
  def self.edit(app_context, request) = Kilau::Format.render(Views::Posts.edit(load_item(app_context, request)))

  def self.add(app_context, request)
    post = Post.new
    PostParams.from_form(request.form("post")).apply(post)
    if post.save(app_context.db)
      Kilau::Format.redirect("/posts/#{post.id}")
    else
      Kilau::Format.render(Views::Posts.new_form(post), status: 422)
    end
  end

  def self.update(app_context, request)
    post = load_item(app_context, request)
    PostParams.from_form(request.form("post")).apply(post)
    if post.save(app_context.db)
      Kilau::Format.redirect("/posts/#{post.id}")
    else
      Kilau::Format.render(Views::Posts.edit(post), status: 422)
    end
  end

  def self.remove(app_context, request)
    load_item(app_context, request).destroy(app_context.db)
    Kilau::Format.redirect("/posts")
  end
end
