class ForumsController < ApplicationController
  before_action :require_login, only: [:new, :create]

  def index
    @forums = Forum.active.order(:name)
  end

  def show
    @forum   = Forum.active.find(params[:id])
    @threads = @forum.posts.active.where(parent_post_id: nil).order(created_at: :desc)
    @post    = Post.new
  end

  def new
    @forum = Forum.new
  end

  def create
    @forum = Forum.new(forum_params.merge(created_by_member: current_member))
    if @forum.save
      redirect_to @forum, notice: "Forum created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def forum_params
    params.require(:forum).permit(:name, :nsfw)
  end
end
