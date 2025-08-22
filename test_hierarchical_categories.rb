#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== 階層カテゴリー機能テスト ==="

begin
  # 既存のカテゴリーを確認
  puts "\n=== 既存カテゴリー一覧 ==="
  Category.all.each do |cat|
    puts "#{cat.id}: #{cat.name} (parent_id: #{cat.parent_id})"
  end

  # 階層カテゴリーのテストデータを作成
  puts "\n=== 階層カテゴリーの作成テスト ==="
  
  # ルートカテゴリーを作成
  tech_category = Category.find_or_create_by(name: 'テクノロジー') do |c|
    c.description = '技術関連のトピック'
  end
  puts "✅ ルートカテゴリー作成: #{tech_category.name} (ID: #{tech_category.id})"

  # 子カテゴリーを作成
  programming_category = Category.find_or_create_by(name: 'プログラミング', parent: tech_category) do |c|
    c.description = 'プログラミング関連'
  end
  puts "✅ 子カテゴリー作成: #{programming_category.full_name} (ID: #{programming_category.id})"

  # 孫カテゴリーを作成
  ruby_category = Category.find_or_create_by(name: 'Ruby', parent: programming_category) do |c|
    c.description = 'Ruby言語関連'
  end
  puts "✅ 孫カテゴリー作成: #{ruby_category.full_name} (ID: #{ruby_category.id})"

  rails_category = Category.find_or_create_by(name: 'Rails', parent: programming_category) do |c|
    c.description = 'Ruby on Rails関連'
  end
  puts "✅ 孫カテゴリー作成: #{rails_category.full_name} (ID: #{rails_category.id})"

  # 別の分岐も作成
  design_category = Category.find_or_create_by(name: 'デザイン') do |c|
    c.description = 'デザイン関連のトピック'
  end
  puts "✅ ルートカテゴリー作成: #{design_category.name} (ID: #{design_category.id})"

  ui_category = Category.find_or_create_by(name: 'UI/UX', parent: design_category) do |c|
    c.description = 'ユーザーインターフェースとユーザーエクスペリエンス'
  end
  puts "✅ 子カテゴリー作成: #{ui_category.full_name} (ID: #{ui_category.id})"

  puts "\n=== 階層構造の検証 ==="
  
  # 階層メソッドのテスト
  puts "\n--- Rubyカテゴリーの階層情報 ---"
  puts "カテゴリー名: #{ruby_category.name}"
  puts "フルネーム: #{ruby_category.full_name}"
  puts "深度: #{ruby_category.depth}"
  puts "ルートか?: #{ruby_category.root?}"
  puts "リーフか?: #{ruby_category.leaf?}"
  
  puts "\n祖先:"
  ruby_category.ancestors.each do |ancestor|
    puts "  #{ancestor.name}"
  end

  puts "\n--- プログラミングカテゴリーの子カテゴリー ---"
  programming_category.children.each do |child|
    puts "  #{child.name} (#{child.full_name})"
  end

  puts "\n--- テクノロジーカテゴリーの全子孫 ---"
  tech_category.descendants.each do |descendant|
    puts "  #{descendant.full_name}"
  end

  puts "\n=== 全階層構造表示 ==="
  def display_hierarchy(categories, level = 0)
    categories.each do |category|
      indent = "  " * level
      puts "#{indent}#{category.name} (ID: #{category.id})"
      display_hierarchy(category.children.order(:name), level + 1) if category.children.any?
    end
  end

  display_hierarchy(Category.root_categories.order(:name))

  puts "\n=== バリデーションテスト ==="
  
  # 循環参照のテスト
  puts "\n--- 循環参照防止テスト ---"
  tech_category.parent = ruby_category
  if tech_category.valid?
    puts "❌ 循環参照が検出されませんでした"
  else
    puts "✅ 循環参照が正しく検出されました: #{tech_category.errors[:parent_id].first}"
  end
  tech_category.parent = nil # リセット

  # 自己参照のテスト
  puts "\n--- 自己参照防止テスト ---"
  ruby_category.parent_id = ruby_category.id
  if ruby_category.valid?
    puts "❌ 自己参照が検出されませんでした"
  else
    puts "✅ 自己参照が正しく検出されました: #{ruby_category.errors[:parent_id].first}"
  end
  
  puts "\n=== テスト完了 ==="
  puts "✅ 階層カテゴリー機能が正常に動作しています！"

rescue => e
  puts "❌ エラーが発生しました: #{e.message}"
  puts e.backtrace.first(5)
end