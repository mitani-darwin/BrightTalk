# メーラークラスで設定セットを指定
class ApplicationMailer < ActionMailer::Base
  default from: 'BrightTalk <noreply@brighttalk.jp>',
          'X-SES-CONFIGURATION-SET' => 'brighttalk-transactional'
end