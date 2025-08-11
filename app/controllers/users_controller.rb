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

  # アカウント管理画面 - Passkeyに更新
  def account
    @user = current_user
    @recent_posts = current_user.posts.recent.limit(5)
    @stats = {
      posts_count: current_user.posts.count
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
      redirect_to user_account_path, notice: "アカウント情報を更新しました。"
    else
      render :edit_account, status: :unprocessable_entity
    end
  end

  # パスワード変更画面
  def edit_password
    @user = current_user
  end

  # パスワード更新 - Passkeyに更新
  def update_password
    @user = current_user

    # パスワード変更パラメータとPasskey設定を分離
    password_params = user_password_params
    passkey_enabled = params[:user][:passkey_enabled] == "1"

    # パスワードが入力されているかチェック
    password_provided = password_params[:password].present?

    begin
      User.transaction do
        # パスワード変更が要求されている場合のみパスワード更新
        if password_provided
          # 現在のパスワードチェック（初回設定以外）
          unless @user.encrypted_password.blank?
            # 専用メソッドを使用してパスワード確認
            unless @user.valid_password_for_change?(password_params[:current_password])
              @user.errors.add(:current_password, "現在のパスワードが正しくありません")
              raise ActiveRecord::RecordInvalid.new(@user)
            end
          end

          # 新しいパスワードの設定
          if password_params[:password] != password_params[:password_confirmation]
            @user.errors.add(:password_confirmation, "パスワードが一致しません")
            raise ActiveRecord::RecordInvalid.new(@user)
          end

          # パスワードの長さチェック（Deviseの設定を使用）
          min_length = Devise.password_length.first
          max_length = Devise.password_length.last

          if password_params[:password].length < min_length
            @user.errors.add(:password, "は#{min_length}文字以上で入力してください")
            raise ActiveRecord::RecordInvalid.new(@user)
          end

          if max_length != Float::INFINITY && password_params[:password].length > max_length
            @user.errors.add(:password, "は#{max_length}文字以内で入力してください")
            raise ActiveRecord::RecordInvalid.new(@user)
          end

          @user.update!(password: password_params[:password])
        end
      end

      # 成功メッセージ
      if password_provided
        flash[:notice] = "パスワードと認証設定を更新しました。"
      else
        flash[:notice] = "認証設定を更新しました。"
      end

      redirect_to user_account_path
    rescue ActiveRecord::RecordInvalid => e
      render :edit_password, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Password update failed: #{e.message}"
      @user.errors.add(:base, "更新に失敗しました。")
      render :edit_password, status: :unprocessable_entity
    end
  end

  private

  def user_password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

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

end