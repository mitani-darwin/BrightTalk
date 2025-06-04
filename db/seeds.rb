# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# テストユーザーの作成
user1 = User.create!(
  name: "田中太郎",
  email: "tanaka@example.com",
  password: "password",
  password_confirmation: "password"
)

user2 = User.create!(
  name: "佐藤花子",
  email: "sato@example.com",
  password: "password",
  password_confirmation: "password"
)

user3 = User.create!(
  name: "山田次郎",
  email: "yamada@example.com",
  password: "password",
  password_confirmation: "password"
)

# テスト記事の作成
20.times do |i|
  user = [user1, user2, user3].sample
  post = user.posts.create!(
    title: "記事タイトル #{i + 1}",
    content: "これは記事 #{i + 1} の内容です。\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  )

  # 各記事にランダムなコメントを追加
  rand(0..5).times do |j|
    commenter = [user1, user2, user3].sample
    post.comments.create!(
      user: commenter,
      content: "これは記事 #{i + 1} に対するコメント #{j + 1} です。とても興味深い内容ですね！"
    )
  end
end

puts "テストデータを作成しました！"
puts "ユーザー: #{User.count}人"
puts "記事: #{Post.count}件"
puts "コメント: #{Comment.count}件"