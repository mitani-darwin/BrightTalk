class ContactsController < ApplicationController
  # お問い合わせ用のコントローラー
  # Contact form controller

  def new
    # お問い合わせフォーム表示
    # Display contact form
    @contact = Contact.new
  end

  def create
    # お問い合わせフォーム送信処理
    # Handle contact form submission
    @contact = Contact.new(contact_params)

    if @contact.valid?
      # メール送信
      # Send email
      ContactMailer.inquiry(@contact).deliver_now
      redirect_to contact_success_path, notice: "お問い合わせを送信しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
    # お問い合わせ送信完了ページ
    # Contact form success page
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
