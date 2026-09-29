# The same handlers as examples/blog/src/controllers/posts.rb.
class PostsController < ApplicationController
  def index = @posts = Post.order(id: :desc).to_a
  def show = @post = Post.find(params[:id])
  def new = @post = Post.new
  def edit = @post = Post.find(params[:id])

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to "/posts/#{@post.id}", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @post = Post.find(params[:id])
    if @post.update(post_params)
      redirect_to "/posts/#{@post.id}", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    Post.find(params[:id]).destroy
    redirect_to "/posts", status: :see_other
  end

  private

  def post_params = params.expect(post: [:title, :content])
end
