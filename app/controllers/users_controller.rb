class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create, :registration_pending]
  before_action :set_user, only: [:show]

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
    @posts = @user.posts.includes(:user, :category, :tags).page(params[:page]).per(10)
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
  end

  # パスワード更新
  def update_password
    @user = current_user
    current_password = params[:user][:current_password]

    # WebAuthn認証のみのユーザーの場合、現在のパスワード確認をスキップ
    if @user.has_webauthn_credentials? && @user.encrypted_password.blank?
      # WebAuthnユーザーで初回パスワード設定の場合
      if @user.update(password_params_with_webauthn)
        bypass_sign_in(@user)
        redirect_to user_account_path, notice: 'パスワードを設定しました。'
      else
        render :edit_password, status: :unprocessable_entity
      end
    elsif current_password.blank?
      # 現在のパスワードが入力されていない場合
      @user.errors.add(:current_password, 'を入力してください')
      render :edit_password, status: :unprocessable_entity
    elsif @user.has_webauthn_credentials? && BCrypt::Password.new(@user.encrypted_password) == current_password
      # WebAuthn認証ユーザーの場合、BCryptで直接確認
      if @user.update(password_params_with_webauthn)
        bypass_sign_in(@user)
        redirect_to user_account_path, notice: 'パスワードを変更しました。'
      else
        render :edit_password, status: :unprocessable_entity
      end
    elsif !@user.has_webauthn_credentials? && @user.valid_password?(current_password)
      # 通常のパスワード認証ユーザーの場合
      if @user.update(password_params_with_webauthn)
        bypass_sign_in(@user)
        redirect_to user_account_path, notice: 'パスワードを変更しました。'
      else
        render :edit_password, status: :unprocessable_entity
      end
    else
      # 現在のパスワードが間違っている場合
      @user.errors.add(:current_password, 'が正しくありません')
      render :edit_password, status: :unprocessable_entity
    end
  end


  private

  def set_user
    # IDが数値の場合のみUserを検索、それ以外は current_user を使用
    if params[:id] && params[:id].match?(/\A\d+\z/)
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end


  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def account_params
    params.require(:user).permit(:name, :email, :avatar)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def password_params_with_webauthn
    params.require(:user).permit(:password, :password_confirmation, :webauthn_enabled)
  end
end