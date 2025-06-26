
class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    # 既にいいねしているかチェック
    existing_like = current_user.likes.find_by(post: @post)

    if existing_like
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, notice: "既にいいねしています。") }
        format.json { render json: { status: "already_liked", likes_count: @post.likes.count } }
      end
      return
    end

    @like = current_user.likes.build(post: @post)

    if @like.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post) }
        format.turbo_stream
        format.json { render json: { status: "created", likes_count: @post.likes.count } }
      end
    else
      Rails.logger.error "Like save failed: #{@like.errors.full_messages.join(', ')}"
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, alert: "いいねできませんでした。") }
        format.json { render json: { status: "error", errors: @like.errors.full_messages } }
      end
    end
  end

  def destroy
    @like = Like.find(params[:id])

    # セキュリティチェック：現在のユーザーのいいねか確認
    unless @like.user == current_user
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, alert: "権限がありません。") }
        format.json { render json: { status: "error", message: "Unauthorized" }, status: :unauthorized }
      end
      return
    end

    # 投稿が一致するかも確認
    unless @like.post == @post
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, alert: "無効なリクエストです。") }
        format.json { render json: { status: "error", message: "Like does not belong to this post" }, status: :bad_request }
      end
      return
    end

    Rails.logger.info "Attempting to destroy like: user_id=#{current_user.id}, post_id=#{@post.id}, like_id=#{@like.id}"

    if @like.destroy
      Rails.logger.info "Like destroyed successfully"
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post) }
        format.turbo_stream
        format.json { render json: { status: "destroyed", likes_count: @post.likes.count } }
      end
    else
      Rails.logger.error "Like destroy failed: #{@like.errors.full_messages.join(', ')}"
      respond_to do |format|
        format.html { redirect_back(fallback_location: @post, alert: "いいねの取り消しができませんでした。") }
        format.json { render json: { status: "error", errors: @like.errors.full_messages } }
      end
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Like not found: #{params[:id]}"
    respond_to do |format|
      format.html { redirect_back(fallback_location: @post, alert: "いいねが見つかりませんでした。") }
      format.json { render json: { status: "error", message: "Like not found" }, status: :not_found }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Post not found: #{params[:post_id]}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "投稿が見つかりませんでした。" }
      format.json { render json: { status: "error", message: "Post not found" }, status: :not_found }
    end
  end
end
