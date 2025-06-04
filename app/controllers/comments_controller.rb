class CommentsController < ApplicationController
  before_action :require_login

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @post, notice: 'コメントを投稿しました'
    else
      redirect_to @post, alert: 'コメントの投稿に失敗しました'
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @comment = @post.comments.find(params[:id])

    if @comment.user == current_user
      @comment.destroy
      redirect_to @post, notice: 'コメントを削除しました'
    else
      redirect_to @post, alert: 'コメントを削除する権限がありません'
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def require_login
    unless logged_in?
      flash[:alert] = 'ログインが必要です'
      redirect_to login_path
    end
  end
end