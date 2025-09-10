
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_post_owner, only: [ :edit, :update, :destroy ]
  before_action :log_user_status

  def index
    # 公開済みの投稿のみ表示
    @posts = Post.published.includes(:user, :category).recent.page(params[:page]).per(10)
  end

  def show
    # 下書きは作者のみ閲覧可能
    if @post.draft? && @post.user != current_user
      redirect_to posts_path, alert: "指定された投稿は存在しません。"
      return
    end

    # 同じ投稿者の前・次の投稿を取得
    @previous_post = @post.previous_post_by_author
    @next_post = @post.next_post_by_author

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
        redirect_to @post, notice: "投稿が作成されました。"
      else
        redirect_to drafts_posts_path, notice: "下書きが保存されました。"
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      if @post.published?
        redirect_to @post, notice: "投稿が更新されました。"
      else
        redirect_to drafts_posts_path, notice: "下書きが更新されました。"
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @post.destroy!
    redirect_to posts_path, notice: "投稿が削除されました。"
  end

  # 下書き一覧
  def drafts
    @posts = current_user.posts.draft.recent.page(params[:page]).per(10)
  end

  # 自動保存（5秒間隔での下書き保存）
  def auto_save
    @post = if params[:id].present?
              current_user.posts.find(params[:id])
    else
              current_user.posts.build
    end

    # バリデーションをスキップして強制保存
    @post.assign_attributes(auto_save_params)
    @post.status = "draft"
    @post.auto_save = true  # 自動保存フラグを設定

    if @post.save(validate: false)
      render json: {
        success: true,
        post_id: @post.id,
        message: "自動保存されました",
        saved_at: Time.current.strftime("%H:%M:%S")
      }
    else
      render json: {
        success: false,
        message: "自動保存に失敗しました"
      }
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def check_post_owner
    unless @post.user == current_user
      redirect_to posts_path, alert: "アクセス権限がありません。"
    end
  end

  def post_params
    attrs = params.require(:post).permit(
      :title, :content, :status, :category_id, :purpose, :target_audience,
      :post_type_id, :key_points, :expected_outcome,
      images: [], videos: []
    )

    # 空配列（新規選択なし）の場合はキーごと削除して既存添付を維持
    if attrs.key?(:images)
      imgs = attrs[:images]
      attrs.delete(:images) if imgs.blank? || (imgs.respond_to?(:all?) && imgs.all?(&:blank?))
    end
    if attrs.key?(:videos)
      vids = attrs[:videos]
      if vids.blank? || (vids.respond_to?(:all?) && vids.all?(&:blank?))
        attrs.delete(:videos)
      else
        # 動画は1つのみ許可するため、最初の1件以外は無視
        if vids.is_a?(Array)
          first = vids.find { |v| v.present? }
          attrs[:videos] = first ? [ first ] : []
        else
          attrs[:videos] = [ vids ]
        end
      end
    end

    attrs
  end

  def auto_save_params
    params.permit(:title, :content, :purpose, :target_audience, :category_id, :post_type_id, :key_points, :expected_outcome)
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
