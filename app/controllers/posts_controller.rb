class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :require_login, except: [:index, :show]
  before_action :correct_user, only: [:edit, :update, :destroy]

  def index
    @posts = Post.includes(:user, :category, :tags, :likes)

    # 検索クエリがある場合
    if params[:search].present?
      @posts = @posts.search(params[:search])
    end

    # カテゴリでフィルタ
    if params[:category_id].present?
      @posts = @posts.by_category(params[:category_id])
    end

    # タグでフィルタ
    if params[:tag].present?
      @posts = @posts.tagged_with(params[:tag])
    end

    @posts = @posts.recent.page(params[:page]).per(10)
    @categories = Category.all
    @popular_tags = Tag.joins(:posts).group(:id).order('COUNT(posts.id) DESC').limit(10)
  end

  def show
    @comment = Comment.new
    @comments = @post.comments.includes(:user).order(created_at: :desc)
  end

  def new
    @post = current_user.posts.build
    @categories = Category.all
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: '投稿が作成されました。'
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: '投稿が更新されました。'
    else
      @categories = Category.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: '投稿が削除されました。'
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :category_id, :tag_list, :image)
  end

  def correct_user
    redirect_to posts_path, alert: '権限がありません。' unless @post.user == current_user
  end
end