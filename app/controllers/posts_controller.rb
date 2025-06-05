class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]

  def index
    @categories = Category.all
    @popular_tags = Tag.joins(:post_tags).group(:id).order('COUNT(post_tags.id) DESC').limit(10)

    # ページネーション付きの投稿取得
    @posts = Post.includes(:user, :category, :tags, :likes)
                 .recent
                 .by_category(params[:category_id])
                 .tagged_with(params[:tag])
                 .search(params[:search])
                 .page(params[:page])
                 .per(10) # 1ページあたり10件
  end

  def show
    @comment = Comment.new
    @comments = @post.comments.includes(:user).order(:created_at)
  end

  def new
    @post = current_user.posts.build
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

  def ensure_owner
    redirect_to posts_path, alert: '権限がありません。' unless @post.user == current_user
  end

  def post_params
    params.require(:post).permit(:title, :content, :category_id, :tag_list, :image)
  end
end