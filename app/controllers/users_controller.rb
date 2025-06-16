class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:account, :edit_account, :update_account, :edit_password, :update_password]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # ユーザーは仮登録状態（confirmed_at が nil）
      # 確認メールを自動で送信
      @user.send_confirmation_instructions

      # セッションに仮登録ユーザーの情報を保存
      session[:pending_user_id] = @user.id

      # 仮登録完了ページにリダイレクト
      redirect_to registration_pending_users_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def registration_pending
    # セッションから仮登録ユーザーの情報を取得
    @user = User.find(session[:pending_user_id]) if session[:pending_user_id]

    # ユーザーが見つからない場合はホームにリダイレクト
    redirect_to root_path unless @user
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.recent.page(params[:page]).per(5)
  end

  # アカウント管理画面
  def account
    @user = current_user
    @webauthn_credentials = current_user.webauthn_credentials.order(:created_at)
    @recent_posts = current_user.posts.recent.limit(5)
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
      redirect_to user_account_path, notice: 'アカウント情報を更新しました。'
    else
      render :edit_account, status: :unprocessable_entity
    end
  end

  # パスワード変更画面
  def edit_password
    @user = current_user

    # WebAuthn認証が設定されている場合はパスワード変更を禁止
    if @user.has_webauthn_credentials?
      redirect_to user_account_path, alert: 'WebAuthn認証が設定されているため、パスワード変更はできません。'
    end
  end

  # パスワード更新
  def update_password
    @user = current_user

    # WebAuthn認証が設定されている場合はパスワード変更を禁止
    if @user.has_webauthn_credentials?
      redirect_to user_account_path, alert: 'WebAuthn認証が設定されているため、パスワード変更はできません。'
      return
    end

    if @user.update_with_password(password_params)
      # パスワード更新後は再ログインが必要
      bypass_sign_in(@user)
      redirect_to user_account_path, notice: 'パスワードを変更しました。'
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def account_params
    params.require(:user).permit(:name, :email, :avatar)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end