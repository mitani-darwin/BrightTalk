
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :delete_image, :delete_video ]
  before_action :check_post_owner, only: [ :edit, :update, :destroy, :delete_image, :delete_video ]
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
    if update_with_additional_images
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
              current_user.posts.friendly.find(params[:id])
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

  # 画像削除アクション
  def delete_image
    @post = current_user.posts.friendly.find(params[:id])
    attachment_id = params[:attachment_id]

    # 指定されたIDの画像を探して削除
    attachment = @post.images.find_by(id: attachment_id)

    if attachment
      filename = attachment.filename.to_s
      attachment.purge

      render json: {
        success: true,
        message: "画像「#{filename}」を削除しました"
      }
    else
      render json: {
        success: false,
        message: "指定された画像が見つかりません"
      }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "投稿が見つかりません"
    }, status: :not_found
  rescue => e
    Rails.logger.error "Image deletion error: #{e.message}"
    render json: {
      success: false,
      message: "画像の削除中にエラーが発生しました"
    }, status: :internal_server_error
  end

  # 動画削除アクション
  def delete_video
    @post = current_user.posts.friendly.find(params[:id])
    attachment_id = params[:attachment_id]

    # 指定されたIDの動画を探して削除
    attachment = @post.videos.find_by(id: attachment_id)

    if attachment
      filename = attachment.filename.to_s
      attachment.purge

      render json: {
        success: true,
        message: "動画「#{filename}」を削除しました"
      }
    else
      render json: {
        success: false,
        message: "指定された動画が見つかりません"
      }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "投稿が見つかりません"
    }, status: :not_found
  rescue => e
    Rails.logger.error "Video deletion error: #{e.message}"
    render json: {
      success: false,
      message: "動画の削除中にエラーが発生しました"
    }, status: :internal_server_error
  end

  private

  def set_post
    @post = Post.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    if Rails.env.test?
      raise ActiveRecord::RecordNotFound
    else
      redirect_to posts_path, alert: "投稿が削除されました。"
    end
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
      images: [], videos: [], video_signed_ids: []
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

  # 画像を既存に追加するためのカスタム更新メソッド
  def update_with_additional_images
    # デバッグ: 送信された画像データを確認
    if params[:post][:images].present?
      Rails.logger.info "=== Image Upload Debug ==="
      Rails.logger.info "Raw images param: #{params[:post][:images].inspect}"
      Rails.logger.info "Images count: #{params[:post][:images].count}"
      params[:post][:images].each_with_index do |img, index|
        Rails.logger.info "Image #{index}: #{img.inspect} (blank?: #{img.blank?})"
        if img.respond_to?(:original_filename)
          Rails.logger.info "  - Original filename: #{img.original_filename}"
        end
      end
      Rails.logger.info "=========================="

      new_images = params[:post][:images].reject(&:blank?)
      Rails.logger.info "Filtered images count: #{new_images.count}"
      @post.images.attach(new_images) if new_images.any?
    end

    # 新しい動画がある場合は置換（動画は1つのみ）
    if params[:post][:videos].present?
      videos_param = Array(params[:post][:videos]) # 配列に変換
      new_videos = videos_param.reject(&:blank?)
      if new_videos.any?
        @post.videos.purge # 既存動画を削除
        @post.videos.attach(new_videos.first) # 最初の動画のみ添付
      end
    end

    # Direct Uploadで送信されたsigned_idがある場合の処理
    if params[:post][:video_signed_ids].present?
      signed_ids = Array(params[:post][:video_signed_ids]).reject(&:blank?)
      if signed_ids.any?
        @post.videos.purge # 既存動画を削除
        signed_ids.each do |signed_id|
          blob = ActiveStorage::Blob.find_signed(signed_id)
          @post.videos.attach(blob) if blob
        end
      end
    end

    # 画像・動画以外のフィールドを更新
    other_params = post_params.except(:images, :videos)
    @post.update(other_params)
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
