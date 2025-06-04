class PostsController < ApplicationController
  before_action :require_login, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = Post.includes(:user).recent.page(params[:page]).per(5)
  end

  def show
    @comment = Comment.new
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: '記事を投稿しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @post unless @post.user == current_user
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: '記事を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy if @post.user == current_user
    redirect_to posts_path, notice: '記事を削除しました'
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content)
  end

  def require_login
    unless logged_in?
      flash[:alert] = 'ログインが必要です'
      redirect_to login_path
    end
  end
end