class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = Post.includes(:category, :user)
    @posts = @posts.by_category(params[:category_id]) if params[:category_id].present?
    @posts = @posts.order(created_at: :desc)

    @categories = Category.all
  end

  def show
    @related_posts = Post.where(category: @post.category)
                         .where.not(id: @post.id)
                         .limit(5)
  end

  def new
    @post = Post.new
    @categories = Category.all
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user # セッション管理がある場合

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
    params.require(:post).permit(:title, :content, :category_id)
  end
end