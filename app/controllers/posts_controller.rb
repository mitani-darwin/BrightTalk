class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy, :delete_image, :delete_video]
  before_action :set_post_for_auto_save, only: [:auto_save]
  before_action :check_post_owner, only: [:edit, :update, :destroy, :delete_image, :delete_video]
  before_action :log_user_status

  def index
    # 公開済みの投稿のみ表示
    @posts = Post.published.includes(:user, :category, :tags, :likes, :bookmarks).recent

    # カテゴリー・投稿タイプでの検索（個別に条件を適用）
    if params[:category_id].present?
      @category = Category.find(params[:category_id])
      @posts = @posts.where(category: @category)
    end

    if params[:post_type_id].present?
      @post_type = PostType.find(params[:post_type_id])
      @posts = @posts.where(post_type: @post_type)
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

    # JSON形式のリクエストに対応
    respond_to do |format|
      format.html # 通常のHTMLレスポンス
      format.json {
        render json: {
          posts: @posts.map do |post|
            {
              id: post.id,
              category: post.category&.name,
              post_type: post.post_type&.name,
              title: post.title,
              content: post.content.to_s.truncate(200),
              user: post.user&.name || "削除されたユーザー", # nil安全性を追加
              user_icon_url: avatar_url_for(post.user),
              image_urls: image_urls_for(post),
              created_at: post.created_at.strftime("%Y年%m月%d日 %H時%M分"),
              likes_count: post.likes.size,
              bookmarks_count: post.bookmarks.size,
              bookmarked_by_current_user: current_user.present? ? current_user.bookmarked?(post) : false
            }
          end,
          total_pages: @posts.total_pages,
          current_page: @posts.current_page
        }
      }
    end
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

    respond_to do |format|
      format.html
      format.json do
        author_json = if @post.user
          {
            id: @post.user.id,
            name: @post.user.name,
            username: @post.user.try(:username),
            icon_url: avatar_url_for(@post.user)
          }
        else
          {
            id: nil,
            name: "削除されたユーザー",
            username: nil,
            icon_url: nil
          }
        end

        render json: {
          post: {
            id: @post.id,
            slug: @post.slug,
            title: @post.title,
            content: @post.content,
            content_html: ApplicationController.helpers.format_content_with_images(@post.content, @post),
            purpose: @post.purpose,
            target_audience: @post.target_audience,
            status: @post.status,
            category: @post.category&.as_json(only: [:id, :name], methods: [:full_name]),
            post_type: @post.post_type&.as_json(only: [:id, :name]),
            tags: @post.tags.pluck(:name),
            likes_count: @post.likes.count,
            bookmarks_count: @post.bookmarks.count,
            comments_count: @post.comments.count,
            image_urls: image_urls_for(@post),
            created_at: @post.created_at.strftime("%Y年%m月%d日 %H時%M分"),
            updated_at: @post.updated_at.strftime("%Y年%m月%d日 %H時%M分"),
            bookmarked_by_current_user: current_user.present? ? current_user.bookmarked?(@post) : false
          },
          author: author_json,
          previous_post: @previous_post&.slice(:id, :slug, :title),
          next_post: @next_post&.slice(:id, :slug, :title),
          related_posts: @related_posts.map { |related|
            related.slice(:id, :slug, :title)
          }
        }
      end
    end
  end

  def new
    @post = current_user.posts.build
  end

  def create
    Rails.logger.info "=== Create Method Debug ==="
    Rails.logger.info "post_id param: #{params[:post_id].inspect}"
    Rails.logger.info "All params: #{params.inspect}"
    Rails.logger.info "=========================="

    # 隠しフィールドからpost_idが送信されている場合は更新処理
    if params[:post_id].present?
      begin
        @post = current_user.posts.friendly.find(params[:post_id])

        # 既存の投稿データを保持しつつ、送信されたパラメータで更新
        update_params = post_params

        # 空の値については既存データを保持
        if update_params[:content].blank? && @post.content.present?
          update_params = update_params.except(:content)
        end
        if update_params[:category_id].blank? && @post.category_id.present?
          update_params = update_params.except(:category_id)
        end
        if update_params[:post_type_id].blank? && @post.post_type_id.present?
          update_params = update_params.except(:post_type_id)
        end

        # video_signed_idsはPostモデルの属性ではないため除外してassign_attributes
        safe_update_params = update_params.except(:videos, :video_signed_ids)
        @post.assign_attributes(safe_update_params)
        @post.status = "published" # 公開状態に設定

        Rails.logger.info "Updating existing post: #{@post.id}"
      rescue ActiveRecord::RecordNotFound
        # 投稿が見つからない場合は新規作成
        safe_post_params = post_params.except(:videos, :video_signed_ids)
        @post = current_user.posts.build(safe_post_params)
        @post.status = "published"
        Rails.logger.info "Post not found, creating new post"
      end
    else
      # 新規投稿の場合もvideo_signed_idsを除外
      safe_post_params = post_params.except(:videos, :video_signed_ids)
      @post = current_user.posts.build(safe_post_params)
      @post.status = "published"
      Rails.logger.info "Creating completely new post"
    end

    Rails.logger.info "=== Post Creation Debug ==="
    Rails.logger.info "Post params: #{post_params.inspect}"
    Rails.logger.info "Post attributes: #{@post.attributes.inspect}"
    Rails.logger.info "Post valid?: #{@post.valid?}"
    Rails.logger.info "Post errors: #{@post.errors.full_messages.inspect}"
    Rails.logger.info "=========================="

    # 動画処理（統合版）
    process_video_uploads

    # 保存とリダイレクト処理（1箇所のみ）
    if @post.save
      if @post.published?
        redirect_to @post, notice: "投稿が作成されました。"
      else
        redirect_to drafts_posts_path, notice: "下書きが保存されました。"
      end
    else
      Rails.logger.error "Post save failed: #{@post.errors.full_messages.join(', ')}"

      # エラー時は新規作成フォームを表示（編集フォームではない）
      render :new, status: :unprocessable_content
    end
  end

  def edit
    respond_to do |format|
      format.html # 通常のHTMLレスポンス
      format.json { render json: { success: true, post: @post.attributes } }
    end
  end

  # update アクションを修正
  def update
    Rails.logger.info "=== Post Update Debug ==="
    Rails.logger.info "All params: #{params.inspect}"
    Rails.logger.info "authenticity_token present: #{params[:authenticity_token].present?}"
    Rails.logger.info "authenticity_token value: #{params[:authenticity_token]}"
    Rails.logger.info "=========================="

    @post.status = :published

    # 動画処理（統合版）
    process_video_uploads

    if update_with_additional_images
      respond_to do |format|
        format.html {
          redirect_to @post, notice: "投稿が更新されました。" # render :edit から redirect に変更
        }
        format.json {
          render json: {
            success: true,
            message: "投稿が更新されました。",
            post: @post.attributes
          }
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
        format.json {
          render json: {
            success: false,
            errors: @post.errors.full_messages
          }, status: :unprocessable_content
        }
      end
    end
  end

  def destroy
    @post.destroy!
    redirect_to posts_path, notice: "投稿が削除されました。"
  end

  def bulk_destroy
    post_ids = params[:post_ids]
    
    if post_ids.blank?
      redirect_to drafts_posts_path, alert: "削除する下書きが選択されていません。"
      return
    end
    
    posts = current_user.posts.draft.where(id: post_ids)
    deleted_count = posts.count
    
    posts.destroy_all
    
    redirect_to drafts_posts_path, notice: "#{deleted_count}件の下書きを削除しました。"
  end

  # 下書き一覧
  def drafts
    @posts = current_user.posts.draft.recent.page(params[:page]).per(10)
  end

  def auto_save
    puts "=== AUTO_SAVE ACTION REACHED ==="
    Rails.logger.info "=== Auto-save Action Called ==="
    Rails.logger.info "Request path: #{request.path}"
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "All params: #{params.keys.inspect}"

    begin
      # パラメータを取得（既存のauto_save_paramsメソッドを使用）
      safe_params = auto_save_params.except(:id, :video_signed_ids, :images, :post_id)

      if safe_params.present?
        # 自動保存時は常にdraftステータスで保存
        safe_params[:status] = 'draft'
        
        # 自動保存フラグを設定（バリデーション回避のため）
        @post.auto_save = true
        
        # video_signed_idsの処理（重複チェック含む）
        if auto_save_params[:video_signed_ids].present?
          process_video_signed_ids_for_auto_save(auto_save_params[:video_signed_ids])
        end
        
        # update!ではなくupdateを使用してバリデーションエラーを回避
        if @post.update(safe_params)
          render json: {
            success: true,
            message: "自動保存が完了しました",
            post_id: @post.id,
            updated_at: @post.updated_at
          }
        else
          # バリデーションエラーがあっても自動保存は成功とみなす
          Rails.logger.info "Auto-save validation errors (ignored): #{@post.errors.full_messages}"
          render json: {
            success: true,
            message: "自動保存が完了しました（一部項目は未入力）",
            post_id: @post.id,
            updated_at: @post.updated_at,
            validation_errors: @post.errors.full_messages
          }
        end
      else
        render json: {
          success: false,
          message: "保存するデータがありません"
        }
      end

    rescue => e
      Rails.logger.error "Auto-save failed: #{e.message}"
      Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join('\n')}"

      render json: {
        success: false,
        message: "自動保存に失敗しました: #{e.message}"
      }, status: :internal_server_error
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

  def set_post_for_auto_save
    Rails.logger.info "=== set_post_for_auto_save Called ==="
    Rails.logger.info "params[:post_id]: #{params[:post_id]}"
    Rails.logger.info "params[:id]: #{params[:id]}"

    if params[:post_id].present?
      Rails.logger.info "Finding post by post_id: #{params[:post_id]}"
      @post = current_user.posts.friendly.find(params[:post_id])
      @post.auto_save = true  # 既存の投稿にもauto_saveフラグを設定
    elsif params[:id].present?
      Rails.logger.info "Finding post by id: #{params[:id]}"
      @post = current_user.posts.friendly.find(params[:id])
      @post.auto_save = true  # 既存の投稿にもauto_saveフラグを設定
    else
      Rails.logger.info "Creating new post for auto_save"
      # auto_save時は新しい投稿を作成（バリデーション回避のためcreateではなく手動作成）
      title = params.dig(:post, :title) || params[:title] || "無題の下書き"
      @post = current_user.posts.new(status: 'draft', title: title)
      @post.auto_save = true
      # バリデーション回避のためsave(validate: false)を使用
      @post.save(validate: false)
    end

    Rails.logger.info "Post found/created: ID=#{@post.id}, Title=#{@post.title}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Post not found, creating new: #{e.message}"
    @post = current_user.posts.new(status: 'draft', title: "無題の下書き")
    @post.auto_save = true
    @post.save(validate: false)
  rescue => e
    Rails.logger.error "Error in set_post_for_auto_save: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(3).join('\n')}"
    @post = current_user.posts.new(status: 'draft', title: "無題の下書き")
    @post.auto_save = true
    @post.save(validate: false)
  end

  def set_post
    @post = Post.includes(:bookmarks, :likes).friendly.find(params[:id])
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
      :og_title, :og_description, :og_image, :videos,
      images: [], videos: [], video_signed_ids: []
    )

    # 空の値のクリーンアップ（既存の処理を保持）
    if attrs.key?(:images)
      imgs = attrs[:images]
      attrs.delete(:images) if imgs.blank? || (imgs.respond_to?(:all?) && imgs.all?(&:blank?))
    end

    # videosパラメータの処理は残すが、実際の添付はprocess_video_attachmentsで処理
    if attrs.key?(:videos)
      vids = attrs[:videos]
      if vids.blank? || (vids.respond_to?(:all?) && vids.all?(&:blank?))
        attrs.delete(:videos)
      end
    end

    # video_signed_idsパラメータの処理を追加
    if attrs.key?(:video_signed_ids)
      signed_ids = attrs[:video_signed_ids]
      if signed_ids.blank? || (signed_ids.respond_to?(:all?) && signed_ids.all?(&:blank?))
        attrs.delete(:video_signed_ids)
      end
    end

    attrs
  end

  # 画像を既存に追加するためのカスタム更新メソッド
  def update_with_additional_images
    # デバッグ: 送信された画像データを確認
    if params[:post].present? && params[:post][:images].present?
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

    # 画像・動画・signed_ids以外のフィールドを更新
    if params[:post].present?
      other_params = post_params.except(:images, :videos, :video_signed_ids)
      @post.update(other_params)
    else
      # params[:post]が存在しない場合は、単純に保存のみ実行
      @post.save
    end
  end

  def auto_save_params
    Rails.logger.info "Auto-save: Processing params structure: #{params.keys.inspect}"
    Rails.logger.info "Auto-save: Post params present: #{params[:post].present?}"

    begin
      # ネストされたpost パラメータを正しく処理
      if params[:post].present?
        Rails.logger.info "Auto-save: Processing nested post params"
        allowed_params = params.require(:post).permit(
          :title, :content, :purpose, :target_audience, :category_id,
          :post_type_id, :key_points, :expected_outcome,
          video_signed_ids: [],
          images: []
        )

        # post_idパラメータを別途取得してmerge（重要な追加部分）
        if params[:post_id].present?
          Rails.logger.info "Auto-save: Adding post_id: #{params[:post_id]}"
          allowed_params[:post_id] = params[:post_id]
        end

        Rails.logger.info "Auto-save: Nested params processed successfully: #{allowed_params.keys.inspect}"
        return allowed_params
      else
        # 従来の平坦な構造もサポート（後方互換性のため）
        Rails.logger.info "Auto-save: Processing flat params structure"
        allowed_params = params.permit(
          :title, :content, :purpose, :target_audience, :post_id, # post_idを追加
          :category_id, :post_type_id, :key_points, :expected_outcome,
          video_signed_ids: [],
          images: []
        )

        Rails.logger.info "Auto-save: Flat params processed successfully: #{allowed_params.keys.inspect}"
        return allowed_params
      end

    rescue ActionController::ParameterMissing => e
      Rails.logger.error "Auto-save: Parameter missing error: #{e.message}"
      Rails.logger.error "Auto-save: Available params: #{params.keys.inspect}"
      raise e
    rescue ActionController::UnpermittedParameters => e
      Rails.logger.error "Auto-save: Unpermitted parameters error: #{e.message}"
      Rails.logger.error "Auto-save: Unpermitted params: #{e.params.inspect}"
      Rails.logger.error "Auto-save: Available params: #{params.keys.inspect}"
      raise e
    rescue => e
      Rails.logger.error "Auto-save: Unexpected error during params processing: #{e.message}"
      Rails.logger.error "Auto-save: Error class: #{e.class}"
      Rails.logger.error "Auto-save: Error backtrace: #{e.backtrace.first(5).join('\n')}"
      Rails.logger.error "Auto-save: Full params structure: #{params.inspect}"
      raise e
    end
  end

  def log_user_status
    Rails.logger.info "=== User Status Debug ==="
    Rails.logger.info "Controller: #{self.class.name}##{action_name}"
    # Rails.logger.info "Current user: #{current_user&.id || 'none'}"
    Rails.logger.info "User signed in?: #{user_signed_in?}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "=========================="
  end

  # 統合された動画処理メソッド（videosとvideo_signed_idsの両方を処理）
  def process_video_uploads
    Rails.logger.info "=== Video Upload Processing Started ==="

    # params[:post]の存在チェックを追加
    return unless params[:post].present?

    # 両方のパラメータをチェック
    videos_present = params[:post][:videos].present?
    signed_ids_present = params[:post][:video_signed_ids].present?

    Rails.logger.info "Videos parameter present: #{videos_present}"
    Rails.logger.info "Video signed_ids parameter present: #{signed_ids_present}"

    return unless videos_present || signed_ids_present

    # 既存の動画を削除（新しい動画で置換）
    if @post.persisted? && (@post.videos.attached? && (videos_present || signed_ids_present))
      Rails.logger.info "Purging existing videos before attaching new ones"
      @post.videos.purge
    end

    # videosパラメータの処理（通常のファイルアップロード）
    if videos_present
      process_direct_video_files
    end

    # video_signed_idsパラメータの処理（Direct Upload）
    if signed_ids_present
      process_video_signed_ids_unified
    end

    Rails.logger.info "=== Video Upload Processing Completed ==="
    Rails.logger.info "Final video count: #{@post.videos.count}"
  end

  # 自動保存用のvideo_signed_ids処理
  def process_video_signed_ids_for_auto_save(signed_ids)
    signed_ids = Array(signed_ids).reject(&:blank?)
    Rails.logger.info "Auto-save: Processing signed IDs: #{signed_ids.inspect}"
    Rails.logger.info "Auto-save: Signed_ids count: #{signed_ids.length}"

    return unless signed_ids.any?

    signed_ids.each_with_index do |signed_id, index|
      Rails.logger.info "Auto-save: Processing signed_id #{index + 1}: #{signed_id.inspect} (length: #{signed_id.length})"

      # バリデーション: 数値のみの場合はスキップ
      if signed_id.to_s.match(/^\d+$/)
        Rails.logger.warn "Auto-save: Skipping invalid numeric signed_id: #{signed_id}"
        next
      end

      # バリデーション: 最小長とタイプチェック
      if signed_id.length < 10 || !signed_id.is_a?(String)
        Rails.logger.warn "Auto-save: Invalid signed_id format: #{signed_id} (length: #{signed_id.length})"
        next
      end

      begin
        blob = ActiveStorage::Blob.find_signed(signed_id)
        if blob
          # 日本語ファイル名の処理
          filename = blob.filename.to_s
          if filename.present?
            Rails.logger.info "Auto-save: Found blob: #{blob.id} (filename: #{filename})"
          end

          # 重複チェック（同じblobが既に添付されていないか）
          unless @post.videos.any? { |v| v.blob_id == blob.id }
            @post.videos.attach(blob)
            Rails.logger.info "Auto-save: Successfully attached video: #{filename} (blob_id: #{blob.id})"
          else
            Rails.logger.info "Auto-save: Video already attached: #{filename}"
          end
        else
          Rails.logger.warn "Auto-save: Could not find blob for signed_id: #{signed_id}"
        end

      rescue ActiveStorage::InvariableError => e
        Rails.logger.error "Auto-save: Invalid signed_id: #{signed_id} - #{e.message}"
      rescue => e
        Rails.logger.error "Auto-save: Failed to attach video with signed_id #{signed_id}: #{e.class.name} - #{e.message}"
      end
    end
  end

  private

  # 通常のファイルアップロード処理
  def process_direct_video_files
    video_param = params[:post][:videos]
    Rails.logger.info "Processing direct video files: #{video_param.inspect}"

    videos = Array(video_param).reject(&:blank?)
    return unless videos.any?

    videos.each_with_index do |video, index|
      begin
        # signed_id かどうかをチェック
        if video.is_a?(String) && video.length > 20 && video.include?('--')
          Rails.logger.info "Detected signed_id in videos parameter: #{video}"
          # signed_id として処理
          process_signed_id_video(video, index)
        elsif video.respond_to?(:original_filename)
          # 通常のファイルアップロード処理
          process_regular_file_video(video, index)
        else
          Rails.logger.warn "Unknown video parameter type: #{video.class} - #{video.inspect}"
        end
      rescue => e
        Rails.logger.error "Failed to attach video #{index + 1}: #{e.message}"
        Rails.logger.error "Error class: #{e.class}"
      end
    end
  end

  private

  def process_signed_id_video(signed_id, index)
    # バリデーション
    if signed_id.to_s.match(/^\d+$/)
      Rails.logger.warn "Skipping invalid numeric signed_id: #{signed_id}"
      return
    end

    if signed_id.length < 10
      Rails.logger.warn "Invalid signed_id format: #{signed_id} (length: #{signed_id.length})"
      return
    end

    begin
      blob = ActiveStorage::Blob.find_signed(signed_id)
      if blob
        filename = blob.filename.to_s
        Rails.logger.info "Found blob: #{blob.id} (filename: #{filename})"

        # 重複チェック
        unless @post.videos.any? { |v| v.blob_id == blob.id }
          @post.videos.attach(blob)
          Rails.logger.info "Successfully attached video via signed_id: #{filename} (blob_id: #{blob.id})"
        else
          Rails.logger.info "Video already attached: #{filename}"
        end
      else
        Rails.logger.warn "Could not find blob for signed_id: #{signed_id}"
      end
    rescue ActiveStorage::InvariableError => e
      Rails.logger.error "Invalid signed_id: #{signed_id} - #{e.message}"
    rescue => e
      Rails.logger.error "Failed to attach video with signed_id #{signed_id}: #{e.class.name} - #{e.message}"
    end
  end

  def process_regular_file_video(video, index)
    # 既存の通常ファイル処理ロジック
    if video.original_filename.present?
      original_filename = video.original_filename

      # 日本語ファイル名の処理
      if original_filename.encoding != Encoding::UTF_8
        begin
          safe_filename = original_filename.force_encoding(Encoding::UTF_8)
          Rails.logger.info "Fixed encoding for filename: #{safe_filename}"
        rescue => e
          Rails.logger.warn "Could not fix encoding for filename: #{original_filename} - #{e.message}"
          safe_filename = original_filename
        end
      else
        safe_filename = original_filename
      end
    end

    @post.videos.attach(video)
    Rails.logger.info "Successfully attached video #{index + 1}: #{safe_filename || 'unknown'}"
  end

  # Direct Upload処理（signed_ids）
  def process_video_signed_ids_unified
    signed_ids = Array(params[:post][:video_signed_ids]).reject(&:blank?)
    Rails.logger.info "Processing signed IDs: #{signed_ids.inspect}"
    Rails.logger.info "Signed_ids count: #{signed_ids.length}"

    return unless signed_ids.any?

    signed_ids.each_with_index do |signed_id, index|
      Rails.logger.info "Processing signed_id #{index + 1}: #{signed_id.inspect} (length: #{signed_id.length})"

      # バリデーション: 数値のみの場合はスキップ
      if signed_id.to_s.match(/^\d+$/)
        Rails.logger.warn "Skipping invalid numeric signed_id: #{signed_id}"
        next
      end

      # バリデーション: 最小長とタイプチェック
      if signed_id.length < 10 || !signed_id.is_a?(String)
        Rails.logger.warn "Invalid signed_id format: #{signed_id} (length: #{signed_id.length})"
        next
      end

      begin
        blob = ActiveStorage::Blob.find_signed(signed_id)
        if blob
          # 日本語ファイル名の処理
          filename = blob.filename.to_s
          if filename.present?
            Rails.logger.info "Found blob: #{blob.id} (filename: #{filename})"
          end

          # 重複チェック（同じblobが既に添付されていないか）
          unless @post.videos.any? { |v| v.blob_id == blob.id }
            @post.videos.attach(blob)
            Rails.logger.info "Successfully attached video: #{filename} (blob_id: #{blob.id})"
          else
            Rails.logger.info "Video already attached: #{filename}"
          end
        else
          Rails.logger.warn "Could not find blob for signed_id: #{signed_id}"
        end

      rescue ActiveStorage::InvariableError => e
        Rails.logger.error "Invalid signed_id: #{signed_id} - #{e.message}"
      rescue => e
        Rails.logger.error "Failed to attach video with signed_id #{signed_id}: #{e.class.name} - #{e.message}"
      end
    end
  end

    def avatar_url_for(user)
    return unless user&.avatar&.attached?
    rails_blob_url(
      user.avatar,
      host: request.host_with_port,
      protocol: request.protocol.delete_suffix("://")
    )
  end

  def image_urls_for(post)
    return [] unless post&.images&.attached?
    post.images.map do |image|
      rails_blob_url(
        image,
        host: request.host_with_port,
        protocol: request.protocol.delete_suffix("://")
      )
    end
  end

end
