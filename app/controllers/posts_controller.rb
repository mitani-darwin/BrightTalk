class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :user_posts]
  before_action :set_post, only: [:show, :edit, :update, :destroy, :publish]
  before_action :set_categories, only: [:index, :new, :edit, :drafts]

  def index
    @posts = Post.published.includes(:user, :category, :likes, :comments)

    # 並び順の指定
    case params[:sort]
    when 'oldest'
      @posts = @posts.order(created_at: :asc)
    when 'popular'
      @posts = @posts.left_joins(:likes)
                     .group('posts.id')
                     .order('COUNT(likes.id) DESC, posts.created_at DESC')
    when 'comments'
      @posts = @posts.left_joins(:comments)
                     .group('posts.id')
                     .order('COUNT(comments.id) DESC, posts.created_at DESC')
    else
      @posts = @posts.order(created_at: :desc)
    end

    # カテゴリーフィルタリング
    if params[:category_id].present?
      @posts = @posts.where(category_id: params[:category_id])
    end

    # タグフィルタリング
    if params[:tag].present?
      @posts = @posts.joins(:tags).where(tags: { name: params[:tag] })
    end

    # ページネーション
    @posts = @posts.page(params[:page]).per(10)

    # 人気タグの取得
    @popular_tags = Tag.joins(:posts).where(posts: { draft: false }).group('tags.id').order('COUNT(posts.id) DESC').limit(10)

    # JSONフォーマットに対応
    respond_to do |format|
      format.html
      format.json do
        render json: {
          posts: @posts.map do |post|
            {
              id: post.id,
              title: post.title,
              content: post.content,
              created_at: post.created_at,
              user: {
                id: post.user.id,
                name: post.user.name
              },
              category: post.category ? {
                id: post.category.id,
                name: post.category.name
              } : nil,
              likes_count: post.likes.count,
              comments_count: post.comments.count
            }
          end,
          meta: {
            current_page: @posts.current_page,
            total_pages: @posts.total_pages,
            total_count: @posts.total_count
          }
        }
      end
    end
  end

  def show
    # 下書きは作成者のみ閲覧可能
    if @post.draft? && @post.user != current_user
      redirect_to posts_path, alert: '指定された投稿は見つかりません。'
      return
    end

    @comment = Comment.new
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.ip_address = request.remote_ip

    # 下書き保存か公開かを判定
    if params[:commit] == '下書き保存'
      @post.draft = true
    else
      @post.draft = false
    end

    Rails.logger.info "Creating post with IP address: #{@post.ip_address}"

    if @post.save
      if @post.draft?
        redirect_to drafts_posts_path, notice: '投稿を下書きとして保存しました。'
      else
        redirect_to @post, notice: '投稿が作成されました。'
      end
    else
      Rails.logger.error "Post creation failed: #{@post.errors.full_messages}"
      set_categories
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # 下書きは作成者のみ編集可能
    if @post.user != current_user
      redirect_to posts_path, alert: 'この投稿を編集する権限がありません。'
    end
  end

  def update
    # 下書き保存か公開かを判定
    if params[:commit] == '下書き保存'
      update_params = post_params.merge(draft: true)
    elsif params[:commit] == '公開'
      update_params = post_params.merge(draft: false)
    else
      update_params = post_params
    end

    if @post.update(update_params)
      if @post.draft?
        redirect_to drafts_posts_path, notice: '投稿を下書きとして保存しました。'
      else
        redirect_to @post, notice: '投稿が更新されました。'
      end
    else
      set_categories
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: '投稿が削除されました。'
  end

  def drafts
    @posts = current_user.posts.drafts.includes(:category, :tags).order(updated_at: :desc).page(params[:page]).per(10)
  end

  def publish
    if @post.user == current_user && @post.draft?
      @post.publish!
      redirect_to @post, notice: '投稿を公開しました。'
    else
      redirect_to posts_path, alert: '公開できませんでした。'
    end
  end

  def user_posts
    @user = User.find(params[:id])
    @posts = @user.posts.published.includes(:user, :category, :tags).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.pdf do
        filename = "#{@user.name}_posts_#{Date.current.strftime('%Y%m%d')}.pdf"

        pdf = render_to_string(
          pdf: filename,
          template: 'posts/user_posts_pdf',
          layout: 'pdf',
          page_size: 'A4',
          margin: { top: 20, bottom: 20, left: 20, right: 20 },
          encoding: 'UTF-8'
        )

        send_data pdf,
                  filename: filename,
                  type: 'application/pdf',
                  disposition: 'attachment'
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def set_categories
    @categories = Category.all
  end

  def post_params
    params.require(:post).permit(:title, :content, :category_id, :tag_list, images: [])
  end
end