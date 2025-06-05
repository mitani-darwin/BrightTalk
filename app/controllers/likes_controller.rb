class LikesController < ApplicationController
  # いいねの作成・削除にはログインが必要
  before_action :authenticate_user!
  before_action :set_post

  def create
    @like = current_user.likes.build(post: @post)

    if @like.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post) }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: @post, alert: 'いいねに失敗しました。')
    end
  end

  def destroy
    @like = current_user.likes.find_by(post: @post)
    @like&.destroy

    respond_to do |format|
      format.html { redirect_back(fallback_location: @post) }
      format.turbo_stream { render :create }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end