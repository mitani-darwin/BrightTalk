# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# 投稿タイプのマスターデータを作成
post_types = [
  {
    name: 'event_study_session',
    description: 'イベント・勉強会',
    display_name: 'イベント・勉強会'
  },
  {
    name: 'project_introduction',
    description: 'プロジェクト紹介',
    display_name: 'プロジェクト紹介'
  },
  {
    name: 'experience_review',
    description: '体験談・レビュー',
    display_name: '体験談・レビュー'
  },
  {
    name: 'technical_article',
    description: '技術記事',
    display_name: '技術記事'
  },
  {
    name: 'self_introduction',
    description: '自己紹介',
    display_name: '自己紹介'
  },
  {
    name: 'question',
    description: '質問',
    display_name: '質問'
  }
]

puts "投稿タイプのマスターデータを作成中..."
post_types.each do |post_type_attrs|
  post_type = PostType.find_or_create_by(name: post_type_attrs[:name]) do |pt|
    pt.description = post_type_attrs[:description]
    pt.display_name = post_type_attrs[:display_name] if pt.respond_to?(:display_name=)
  end
  puts "- #{post_type.description} を作成しました" if post_type.persisted?
end

puts "マスターデータの作成が完了しました。"