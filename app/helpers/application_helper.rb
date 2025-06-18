module ApplicationHelper
  # Deviseのパスワード最小文字数を取得
  def devise_minimum_password_length
    Devise.password_length.first
  end

  # Deviseのパスワード最大文字数を取得
  def devise_maximum_password_length
    Devise.password_length.last
  end

  # パスワード要件の説明文を生成
  def password_requirement_text
    min_length = devise_minimum_password_length
    max_length = devise_maximum_password_length

    length_text = if max_length == Float::INFINITY
                    "#{min_length}文字以上"
                  else
                    "#{min_length}文字以上#{max_length}文字以内"
                  end

    "#{length_text}、英字・数字・記号を各1文字以上"
  end

  # パスワード強度の詳細説明
  def password_strength_requirements
    [
      "#{devise_minimum_password_length}文字以上の長さ",
      "英字（a-z, A-Z）を1文字以上",
      "数字（0-9）を1文字以上",
      "記号（!@#$%^&*など）を1文字以上",
      "推測されにくいパスワード"
    ]
  end

  # 推測されやすいパスワードの例
  def weak_password_examples
    [
      "連続した文字（abc123、123456など）",
      "キーボード配列（qwerty、asdfghなど）",
      "一般的な単語（password、admin、testなど）",
      "ユーザー名やメールアドレスの一部",
      "年号や生年月日",
      "文字と数字のみの組み合わせ（記号なし）"
    ]
  end
end