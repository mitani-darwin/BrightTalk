
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :check_post_owner, only: [:edit, :update, :destroy]
  before_action :log_user_status

  def index
    # 公開済みの投稿のみ表示
    @posts = Post.published.includes(:user, :category).recent.page(params[:page]).per(10)
  end

  def show
    # 下書きは作者のみ閲覧可能
    if @post.draft? && @post.user != current_user
      redirect_to posts_path, alert: '指定された投稿は存在しません。'
      return
    end

    # コメント投稿フォーム用の新しいコメントインスタンスを作成
    @comment = Comment.new
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      if @post.published?
        redirect_to @post, notice: '投稿が作成されました。'
      else
        redirect_to drafts_posts_path, notice: '下書きが保存されました。'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      if @post.published?
        redirect_to @post, notice: '投稿が更新されました。'
      else
        redirect_to drafts_posts_path, notice: '下書きが更新されました。'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    redirect_to posts_path, notice: '投稿が削除されました。'
  end

  # 下書き一覧
  def drafts
    @posts = current_user.posts.draft.recent.page(params[:page]).per(10)
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def check_post_owner
    unless @post.user == current_user
      redirect_to posts_path, alert: 'アクセス権限がありません。'
    end
  end

  def post_params
    params.require(:post).permit(:title, :content, :status, :category_id, images: [])
  end

  def log_user_status
    Rails.logger.info "=== User Status Debug ==="
    Rails.logger.info "Controller: #{self.class.name}##{action_name}"
    Rails.logger.info "Current user: #{current_user&.id || 'none'}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "=========================="
  end
end