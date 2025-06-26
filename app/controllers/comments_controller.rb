class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  before_action :set_comment, only: [ :destroy ]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @post, notice: "コメントが投稿されました。"
    else
      redirect_to @post, alert: "コメントの投稿に失敗しました。"
    end
  end

  def destroy
    if @comment.user == current_user
      @comment.destroy
      redirect_to @post, notice: "コメントが削除されました。"
    else
      redirect_to @post, alert: "コメントの削除権限がありません。"
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def render_not_found
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false }
      format.json { render json: { error: "リソースが見つかりません" }, status: :not_found }
      format.any { head :not_found }
    end
  end
end
