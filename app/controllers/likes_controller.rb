class LikesController < ApplicationController
  before_action :authenticate_user!, only: [:create, :destroy]
  before_action :set_post

  def index
    @likes = @post.likes.includes(:user)
    render json: @likes
  end

  def create
    Rails.logger.info "=== Like Create Action Started ==="

    existing_like = @post.likes.find_by(user: current_user)
    Rails.logger.info "Existing like: #{existing_like.present?}"

    if existing_like
      existing_like.destroy
      Rails.logger.info "Like removed"
    else
      @like = @post.likes.create!(user: current_user)
      Rails.logger.info "New like created: #{@like.id}"
    end

    @post.reload
    Rails.logger.info "Post likes count: #{@post.likes.count}"
    Rails.logger.info "User liked?: #{current_user.liked?(@post)}"

    respond_to do |format|
      format.turbo_stream do
        Rails.logger.info "=== Responding with Turbo Stream for like_button_#{@post.id} ==="
      end
      format.html { redirect_to @post }
    end
  end


  def destroy
    @like = @post.likes.find_by(user: current_user)
    @like&.destroy
    @post.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: '投稿が見つかりません。'
  end
end