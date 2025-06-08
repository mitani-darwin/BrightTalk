class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :set_categories, only: [:index, :new, :edit] # この行を追加

  def index
    @posts = Post.includes(:user, :category, :likes, :comments)

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
    else # デフォルトは新しい順
      @posts = @posts.order(created_at: :desc)
    end

    # カテゴリーフィルタリング
    if params[:category_id].present?
      @posts = @posts.where(category_id: params[:category_id])
    end

    # タグフィルタリング（もし実装している場合）
    if params[:tag].present?
      @posts = @posts.joins(:tags).where(tags: { name: params[:tag] })
    end

    # ページネーション
    @posts = @posts.page(params[:page]).per(10)

    # 人気タグの取得
    @popular_tags = Tag.joins(:posts).group('tags.id').order('COUNT(posts.id) DESC').limit(10)
  end

  def show
    @comment = Comment.new
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to @post, notice: '投稿が作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: '投稿が更新されました。'
    else
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

  def set_categories
    @categories = Category.all
  end

  def post_params
    params.require(:post).permit(:title, :content, :category_id, :image, :tag_list)
  end
end