class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: [ :destroy ]
  before_action :restrict_comment_ip!, only: [ :create ]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    # クライアントIP保存
    @comment.client_ip = request.remote_ip

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

  COMMENT_IP_RESTRICTION_MESSAGES = {
    foreign: "日本国外からはコメントを投稿できません。",
    hosting: "VPN・プロキシ経由ではコメントを投稿できません。",
    unavailable: "接続元を確認できなかったため、コメントを投稿できません。"
  }.freeze

  # 日本国外・VPN（クラウド／ホスティング事業者）からの投稿を拒否する
  def restrict_comment_ip!
    return unless CommentIpRestriction.enabled?

    status = CommentIpRestriction.new.check(request.remote_ip)
    return if status == :allowed

    Rails.logger.info("[CommentIpRestriction] コメント投稿を拒否しました ip=#{request.remote_ip} reason=#{status}")
    redirect_to @post, alert: COMMENT_IP_RESTRICTION_MESSAGES.fetch(status)
  end

  def set_post
    @post = Post.friendly.find(params[:post_id])
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
