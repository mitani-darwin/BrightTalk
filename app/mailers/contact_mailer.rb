class ContactMailer < ApplicationMailer
  # お問い合わせメール送信用のメーラー
  # Contact form mailer

  def inquiry(contact)
    @contact = contact
    
    mail(
      to: 'info@brighttalk.jp',
      reply_to: @contact.email,
      subject: "【お問い合わせ】#{@contact.subject}"
    )
  end
end