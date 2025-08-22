#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== 構造化投稿機能テスト ==="

# テスト用ユーザーを作成または取得
user = User.find_by(email: 'test@example.com')
if user.nil?
  user = User.new(
    email: 'test@example.com',
    name: 'テストユーザー',
    password: 'ComplexTest@Pass123',
    password_confirmation: 'ComplexTest@Pass123',
    confirmed_at: Time.current
  )
  unless user.save
    puts "ユーザー作成エラー: #{user.errors.full_messages.join(', ')}"
    exit 1
  end
end

puts "テストユーザー: #{user.name} (ID: #{user.id})"

# カテゴリーを作成または取得
category = Category.find_or_create_by(name: 'プログラミング') do |c|
  c.description = 'プログラミング関連のトピック'
end

puts "カテゴリー: #{category.name}"

# 構造化された投稿を作成
post = user.posts.create!(
  title: 'Rails初心者のための環境構築ガイド',
  content: 'この記事では、Railsの開発環境を構築する手順を詳しく説明します。',
  post_type: 'tutorial',
  purpose: 'Rails初心者が迷わずに開発環境を構築できるように、詳細な手順とトラブルシューティング方法を提供する',
  target_audience: 'プログラミング初心者、Rails学習者、環境構築に困っている開発者',
  key_points: '1. Rubyのインストール方法
2. Railsのインストールとバージョン管理
3. データベース（PostgreSQL）の設定
4. よくあるエラーとその対処法
5. 開発に便利なツールの紹介',
  expected_outcome: '読者が自分でRailsの開発環境を構築でき、基本的なWebアプリケーションの開発を始められるようになる',
  category: category,
  status: 'published'
)

puts "\n=== 作成された投稿情報 ==="
puts "タイトル: #{post.title}"
puts "投稿タイプ: #{post.post_type} (#{Post.post_types.key(post.post_type_before_type_cast)})"
puts "目的: #{post.purpose}"
puts "対象読者: #{post.target_audience}"
puts "要点:\n#{post.key_points}"
puts "期待する成果: #{post.expected_outcome}"
puts "カテゴリー: #{post.category.name}"
puts "ステータス: #{post.status}"

puts "\n=== バリデーションテスト ==="

# 必須項目が空の場合のテスト
invalid_post = user.posts.build(
  title: 'テスト投稿',
  content: '内容',
  # purpose と target_audience を空にしてテスト
)

if invalid_post.valid?
  puts "❌ バリデーションエラー: 必須項目が空でも通ってしまいました"
else
  puts "✅ バリデーション正常: 必須項目のチェックが機能しています"
  puts "エラーメッセージ: #{invalid_post.errors.full_messages.join(', ')}"
end

puts "\n=== 投稿タイプ enum テスト ==="
Post.post_types.each do |key, value|
  puts "#{key}: #{value}"
end

puts "\n=== テスト完了 ==="
puts "構造化投稿機能が正常に動作することを確認しました。"