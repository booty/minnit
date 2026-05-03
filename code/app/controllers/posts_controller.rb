class PostsController < ApplicationController
  before_action :require_login, only: [:create]

  def show
    @post    = Post.active.where(parent_post_id: nil).find(params[:id])
    @replies = @post.replies.active.order(created_at: :asc)
    @reply   = Post.new
  end

  def create
    if params[:forum_id]
      create_thread
    else
      create_reply
    end
  end

  private

  def create_thread
    @forum = Forum.active.find(params[:forum_id])
    @post  = Post.new(thread_params.merge(forum: @forum, member: current_member))
    if @post.save
      redirect_to @post, notice: "Thread created."
    else
      @threads = @forum.posts.active.where(parent_post_id: nil).order(created_at: :desc)
      render "forums/show", status: :unprocessable_entity
    end
  end

  def create_reply
    @post  = Post.active.where(parent_post_id: nil).find(params[:post_id])
    @reply = Post.new(reply_params.merge(parent_post: @post, member: current_member))
    if @reply.save
      redirect_to @post, notice: "Reply posted."
    else
      @replies = @post.replies.active.order(created_at: :asc)
      render :show, status: :unprocessable_entity
    end
  end

  def thread_params
    params.require(:post).permit(:title, :body)
  end

  def reply_params
    params.require(:post).permit(:body)
  end
end
