# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # DeviseのRESTfulアクションを明示的に定義

  # GET /users/sign_up
  def new
    super
  end

  # POST /users
  def create
    super do |resource|
      if resource.persisted?
        # デフォルトのフラッシュメッセージをクリア
        flash.delete(:notice)
        # カスタムメッセージを設定
        flash[:notice] = "仮登録が完了しました。確認メールをお送りしましたので、メール内のリンクをクリックして本登録を完了してください。"
      end
    end
  end

  # GET /users/edit
  def edit
    super
  end

  # PATCH/PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  protected

  def after_sign_up_path_for(resource)
    Rails.logger.debug "after_sign_up_path_for called for #{resource.email}"
    # ユーザーをサインアウトさせて新規登録画面に遷移
    sign_out(resource)
    new_user_registration_path
  end

  def after_inactive_sign_up_path_for(resource)
    Rails.logger.debug "after_inactive_sign_up_path_for called for #{resource.email}"
    # 確認待ち状態でも新規登録画面にリダイレクト
    new_user_registration_path
  end
end