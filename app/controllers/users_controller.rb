
class UsersController < ApplicationController
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

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end