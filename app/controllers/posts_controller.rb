class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :check_owner, only: [ :edit, :update, :destroy ]

  def index
    @posts = Post.published.includes(:user, :category, :tags, :likes, images_attachments: :blob)

    # カテゴリーフィルタ
    if params[:category_id].present?
      @posts = @posts.where(category_id: params[:category_id])
    end

    # タグフィルタ
    if params[:tag].present?
      @posts = @posts.joins(:tags).where(tags: { name: params[:tag] })
    end

    # キーワード検索
    if params[:search].present?
      @posts = @posts.where("title ILIKE ? OR content ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @posts = @posts.order(created_at: :desc)

    # ページネーション（Kaminariを使用）
    @posts = @posts.page(params[:page])
  end

  def show
    @comment = Comment.new
    @comments = @post.comments.includes(:user).order(created_at: :asc)
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    @post.ip_address = request.remote_ip

    if @post.save
      redirect_to @post, notice: "投稿が作成されました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "投稿が更新されました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "投稿が削除されました。"
  end

  def drafts
    @posts = current_user.posts.draft.order(created_at: :desc)
    @posts = @posts.page(params[:page])
  end

  def user_posts
    @user = User.find(params[:id])
    @posts = @user.posts.published.includes(:category, :tags, :likes, images_attachments: :blob)
    @posts = @posts.order(created_at: :desc)
    @posts = @posts.page(params[:page])
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :category_id, :tag_list, :draft, images: [])
  end

  def check_owner
    redirect_to posts_path, alert: "権限がありません。" unless @post.user == current_user
  end
end
