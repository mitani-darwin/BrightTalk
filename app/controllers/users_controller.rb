class UsersController < ApplicationController
  before_action :authenticate_user!, except: [ :new, :create, :registration_pending ]
  before_action :set_user, only: [ :show ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # ユーザーは仮登録状態（confirmed_at が nil）
      # 確認メールを自動で送信（重複防止付き）
      @user.send_confirmation_instructions_once

      # セッションに仮登録ユーザーの情報を保存
      session[:pending_user_id] = @user.id

      # 仮登録完了ページにリダイレクト
      redirect_to registration_pending_users_path
    else
      render :new, status: :unprocessable_content
    end
  end

  def registration_pending
    # セッションから仮登録ユーザーの情報を取得
    @user = User.find(session[:pending_user_id]) if session[:pending_user_id]

    # ユーザーが見つからない場合はホームにリダイレクト
    redirect_to root_path unless @user
  end

  def show
    @posts = @user.posts.includes(:user, :category, :tags).page(params[:page]).per(10)
  end

  # アカウント管理画面 - Passkeyに更新
  def account
    @user = current_user
    @recent_posts = current_user.posts.recent.limit(5)
    @passkeys = current_user.webauthn_credentials  # または current_user.passkeys
    @stats = {
      posts_count: current_user.posts.count,
      comments_count: current_user.comments.count,
      likes_given: current_user.likes.count,
      likes_received: Like.joins(:post).where(posts: { user: current_user }).count
    }
  end

  # アカウント編集画面
  def edit_account
    @user = current_user
  end

  # アカウント更新
  def update_account
    @user = current_user

    if @user.update(account_params)
      redirect_to account_user_path(current_user), notice: "アカウント情報を更新しました。"
    else
      render :edit_account, status: :unprocessable_content
    end
  end

  # アカウント削除
  def destroy_account
    @user = current_user

    if @user.destroy
      redirect_to root_path, notice: "アカウントを削除しました。ご利用ありがとうございました。"
    else
      redirect_to account_user_path(current_user), alert: "アカウントの削除に失敗しました。"
    end
  end

  private

  def set_user
    # IDまたはslugでUserを検索、見つからない場合は current_user を使用
    if params[:id]
      @user = User.friendly.find(params[:id])
    else
      @user = current_user
    end
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end

  def account_params
    params.require(:user).permit(:name, :email, :avatar, :bio, :header_image,
                                 :twitter_url, :github_url)
  end
end
