
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :delete_image, :delete_video ]
  before_action :check_post_owner, only: [ :edit, :update, :destroy, :delete_image, :delete_video ]
  before_action :log_user_status

  def index
    # 公開済みの投稿のみ表示
    @posts = Post.published.includes(:user, :category, :tags).recent

    # カテゴリー・投稿タイプでの検索
    if params[:category_id].present? || (params[:post_type_id]).present?
      @category = Category.find(params[:category_id]) if params[:category_id].present?
      @post_type = PostType.find(params[:post_type_id]) if params[:post_type_id].present?
      @posts = @posts.where(category: @category, post_type: @post_type)
    end

    # 投稿期間での検索
    if params[:date_range].present?
      date_range = params[:date_range].split(' から ')
      if date_range.length == 2
        begin
          start_date = Date.parse(date_range[0].strip)
          end_date = Date.parse(date_range[1].strip)
          @posts = @posts.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        rescue Date::Error
          # 日付のパースに失敗した場合は無視
          Rails.logger.warn "Invalid date range format: #{params[:date_range]}"
        end
      end
    end

    @posts = @posts.page(params[:page]).per(10)
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

    # 関連記事を取得
    @related_posts = @post.related_posts(limit: 6)

    # コメント投稿フォーム用の新しいコメントインスタンスを作成
    @comment = Comment.new
  end

  def new
    @post = current_user.posts.build
  end

  def create
    # 隠しフィールドからpost_idが送信されている場合は更新処理
    if params[:post_id].present?
      begin
        @post = current_user.posts.friendly.find(params[:post_id])
        @post.assign_attributes(post_params)
        @post.status = "published" # 公開状態に設定
      rescue ActiveRecord::RecordNotFound
        # 投稿が見つからない場合は新規作成
        @post = current_user.posts.build(post_params)
        @post.status = "published"
      end
    else
      @post = current_user.posts.build(post_params)
      @post.status = "published"
    end

    # 投稿ボタンがクリックされた場合は公開状態に設定
    @post.status = "published"

    Rails.logger.info "=== Post Creation Debug ==="
    Rails.logger.info "Post params: #{post_params.inspect}"
    Rails.logger.info "Post attributes: #{@post.attributes.inspect}"
    Rails.logger.info "Post valid?: #{@post.valid?}"
    Rails.logger.info "Post errors: #{@post.errors.full_messages.inspect}"
    Rails.logger.info "=========================="

    # 修正：videosパラメータからsigned_idを処理
    if params[:post][:videos].present?
      video_param = params[:post][:videos]
      Rails.logger.info "Processing video parameter: #{video_param.inspect}"

      if video_param.is_a?(String) && video_param.present?
        # signed_idの場合の処理
        begin
          blob = ActiveStorage::Blob.find_signed(video_param)
          if blob
            @post.videos.attach(blob)
            Rails.logger.info "Successfully attached video: #{blob.filename} to new post"
          else
            Rails.logger.warn "Could not find blob for signed_id: #{video_param}"
          end
        rescue => e
          Rails.logger.error "Failed to attach video: #{e.message}"
        end
      elsif video_param.respond_to?(:each)
        # 配列の場合の処理
        Array(video_param).reject(&:blank?).each do |signed_id|
          begin
            blob = ActiveStorage::Blob.find_signed(signed_id)
            if blob
              @post.videos.attach(blob)
              Rails.logger.info "Successfully attached video: #{blob.filename} to new post"
            else
              Rails.logger.warn "Could not find blob for signed_id: #{signed_id}"
            end
          rescue => e
            Rails.logger.error "Failed to attach video: #{e.message}"
          end
        end
      end

      # 既存のvideo_signed_ids処理も維持（後方互換性のため）
      if params[:post][:video_signed_ids].present?
        signed_ids = Array(params[:post][:video_signed_ids]).reject(&:blank?)
        if signed_ids.any?
          signed_ids.each do |signed_id|
            begin
              blob = ActiveStorage::Blob.find_signed(signed_id)
              if blob
                @post.videos.attach(blob)
                Rails.logger.info "Successfully attached video: #{blob.filename} to new post"
              else
                Rails.logger.warn "Could not find blob for signed_id: #{signed_id}"
              end
            rescue => e
              Rails.logger.error "Failed to attach video: #{e.message}"
            end
          end
        end
      end

      if @post.save
        if @post.published?
          redirect_to @post, notice: "投稿が作成されました。"
        else
          redirect_to drafts_posts_path, notice: "下書きが保存されました。"
        end
      else
        Rails.logger.error "Post save failed: #{@post.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_content
      end
    end
  end

  def edit
  end

  def update
    Rails.logger.info "=== Post Update Debug ==="
    Rails.logger.info "All params: #{params.inspect}"
    Rails.logger.info "authenticity_token present: #{params[:authenticity_token].present?}"
    Rails.logger.info "authenticity_token value: #{params[:authenticity_token]}"
    Rails.logger.info "=========================="

    if update_with_additional_images
      redirect_to @post, notice: "投稿が更新されました。"
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
              # slugまたは数値IDでの検索
              current_user.posts.friendly.find(params[:id])
            else
              current_user.posts.build
            end

    # idパラメータを除外してからassign_attributes（ID破壊を防止）
    safe_params = auto_save_params.except(:id, :video_signed_ids)
    @post.assign_attributes(safe_params)
    @post.status = "draft"
    @post.auto_save = true  # 自動保存フラグを設定

    # Direct Uploadで送信されたsigned_idがある場合の処理
    if params[:video_signed_ids].present?
      signed_ids = Array(params[:video_signed_ids]).reject(&:blank?)
      if signed_ids.any?
        @post.videos.purge # 既存動画を削除
        signed_ids.each do |signed_id|
          begin
            blob = ActiveStorage::Blob.find_signed(signed_id)
            if blob
              @post.videos.attach(blob)
              Rails.logger.info "Auto-save: Successfully attached video: #{blob.filename} to post #{@post.id}"
            else
              Rails.logger.warn "Auto-save: Could not find blob for signed_id: #{signed_id}"
            end
          rescue => e
            Rails.logger.error "Auto-save: Failed to attach video: #{e.message}"
          end
        end
      end
    end

    if @post.save(validate: false)
      render json: {
        success: true,
        post_id: @post.friendly_id || @post.id, # slugを優先して返す
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
      :post_type_id, :key_points, :expected_outcome, :meta_description,
      :og_title, :og_description, :og_image,
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

      # メソッドの最後に追加
      Rails.logger.info "=== Video Attachment Debug ==="
      Rails.logger.info "Videos attached: #{@post.videos.attached?}"
      Rails.logger.info "Video count: #{@post.videos.count}"
      @post.videos.each_with_index do |video, index|
        Rails.logger.info "Video #{index}: #{video.filename} (content_type: #{video.content_type})"
      end
      Rails.logger.info "=============================="
    end

    # Direct Uploadで送信されたsigned_idがある場合の処理
    if params[:post][:video_signed_ids].present?
      signed_ids = Array(params[:post][:video_signed_ids]).reject(&:blank?)
      if signed_ids.any?
        @post.videos.purge # 既存動画を削除
        signed_ids.each do |signed_id|
          begin
            blob = ActiveStorage::Blob.find_signed(signed_id)
            if blob
              @post.videos.attach(blob)
              Rails.logger.info "Successfully attached video: #{blob.filename} to post #{@post.id}"
            else
              Rails.logger.warn "Could not find blob for signed_id: #{signed_id}"
            end
          rescue ActiveStorage::InvariableError => e
            Rails.logger.error "Failed to attach video with signed_id #{signed_id}: #{e.message}"
          end
        end
      end
    end

    Rails.logger.info "=== Parameters Debug ==="
    Rails.logger.info "video_signed_ids present: #{params[:post][:video_signed_ids].present?}"
    Rails.logger.info "video_signed_ids value: #{params[:post][:video_signed_ids].inspect}"
    Rails.logger.info "videos present: #{params[:post][:videos].present?}"
    Rails.logger.info "videos value: #{params[:post][:videos].inspect}"
    Rails.logger.info "========================="

    # 画像・動画・signed_ids以外のフィールドを更新
    other_params = post_params.except(:images, :videos, :video_signed_ids)
    @post.update(other_params)
  end

  def auto_save_params
    # idを含めず、安全なパラメータのみ許可
    params.permit(:title, :content, :purpose, :target_audience, :category_id, :post_type_id, :key_points, :expected_outcome, video_signed_ids: [])
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
