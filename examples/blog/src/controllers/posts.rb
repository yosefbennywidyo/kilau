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
      .add("/:id<int>", get { |app_context, request| show(app_context, request) })
      .add("/:id<int>/edit", get { |app_context, request| edit(app_context, request) })
      .add("/:id<int>", patch { |app_context, request| update(app_context, request) })
      .add("/:id<int>", delete { |app_context, request| remove(app_context, request) })
  end

  def self.load_item(app_context, request)
    post = Post.find_by_id(app_context.db, request.path_int("id"))
    raise Kilau::Error::NotFound, "post not found" if post.nil?
    post
  end

  # The redirect a handler returns to send a guest to the sign-in form, or nil
  # when someone is signed in. Called first in every handler that changes or
  # edits posts, before the database is touched.
  def self.require_login(request)
    id = request.session["user_id"]
    return Kilau::Format.redirect("/login") if id.nil? || id.empty?
    nil
  end

  def self.list(app_context, request) = Kilau::Format.render(Views::Posts.list(Post.all(app_context.db), PageHelper.for(app_context, request)))
  def self.show(app_context, request) = Kilau::Format.render(Views::Posts.show(load_item(app_context, request), PageHelper.for(app_context, request)))

  def self.new_form(app_context, request)
    denied = require_login(request)
    return denied unless denied.nil?
    Kilau::Format.render(Views::Posts.new_form(Post.new, PageHelper.for(app_context, request)))
  end

  def self.edit(app_context, request)
    denied = require_login(request)
    return denied unless denied.nil?
    Kilau::Format.render(Views::Posts.edit(load_item(app_context, request), PageHelper.for(app_context, request)))
  end

  def self.add(app_context, request)
    denied = require_login(request)
    return denied unless denied.nil?
    post = Post.new
    PostParams.from_form(request.form("post")).apply(post)
    if post.save(app_context.db)
      Kilau::Format.redirect("/posts/#{post.id}")
    else
      Kilau::Format.render(Views::Posts.new_form(post, PageHelper.for(app_context, request)), status: 422)
    end
  end

  def self.update(app_context, request)
    denied = require_login(request)
    return denied unless denied.nil?
    post = load_item(app_context, request)
    PostParams.from_form(request.form("post")).apply(post)
    if post.save(app_context.db)
      Kilau::Format.redirect("/posts/#{post.id}")
    else
      Kilau::Format.render(Views::Posts.edit(post, PageHelper.for(app_context, request)), status: 422)
    end
  end

  def self.remove(app_context, request)
    denied = require_login(request)
    return denied unless denied.nil?
    load_item(app_context, request).destroy(app_context.db)
    Kilau::Format.redirect("/posts")
  end
end
