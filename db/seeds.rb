require 'thread'

# データベースをクリア
puts "データベースをクリアしています..."
PostTag.destroy_all
Like.destroy_all
Comment.destroy_all
Post.destroy_all
Tag.destroy_all
Category.destroy_all
User.destroy_all

puts "マルチスレッドでサンプルデータを作成します（総計5000件）..."
puts "使用可能なCPUコア数: #{Etc.nprocessors}"

# スレッド数の設定（小規模データなので4スレッドに制限）
THREAD_COUNT = [Etc.nprocessors, 4].min
puts "使用スレッド数: #{THREAD_COUNT}"

start_time = Time.current

# 共通データ
japanese_names = [
  "田中太郎", "佐藤花子", "鈴木一郎", "高橋美咲", "伊藤健太",
  "渡辺里奈", "山本大輔", "中村優子", "小林翔太", "加藤恵美",
  "吉田康雄", "山田真由美", "佐々木拓也", "松本彩香", "井上智也",
  "木村綾乃", "林直樹", "清水美穂", "山口雅人", "森田千恵",
  "池田良太", "橋本愛", "岡田修", "福田麻衣", "石井達也",
  "村田沙織", "藤田健", "青木美智子", "野村浩", "大塚由香",
  "西田亮", "前田真理", "竹内雄介", "三宅智美", "河野正一",
  "坂本恵子", "小川学", "武田薫", "松井康夫", "金子千尋"
]

post_titles = [
  "Rubyの基礎知識について", "Railsアプリケーション開発のコツ",
  "データベース設計のベストプラクティス", "フロントエンド技術の最新動向",
  "アジャイル開発の導入事例", "セキュリティ対策の重要性",
  "クラウドサービス活用法", "機械学習入門ガイド",
  "モバイルアプリ開発手法", "DevOpsの実践方法",
  "レスポンシブデザインのテクニック", "APIの設計と実装",
  "テスト駆動開発の実践", "コードレビューの効果的な方法",
  "リファクタリングのベストプラクティス", "パフォーマンス最適化の手法",
  "データベースチューニング技法", "サーバーサイド開発のポイント",
  "フロントエンドフレームワーク比較", "CI/CD環境の構築方法"
]

post_contents = [
  "今回は技術的な内容について詳しく解説していきます。実際の開発現場での経験を踏まえて、初心者の方にも分かりやすく説明いたします。",
  "プロジェクトを進める上で重要なポイントをまとめました。効率的な開発手法や、チーム運営のコツについても触れています。",
  "最新の技術トレンドと、それらを実際のプロジェクトに適用する方法について考察しています。具体的な実装例も含めて紹介します。",
  "この分野での経験を活かして、実践的なアドバイスをお伝えします。失敗事例から学んだ教訓も含めて共有いたします。",
  "実際のコード例を交えながら、段階的に説明していきます。初心者から上級者まで、幅広い層に役立つ内容を心がけています。"
]

categories_data = [
  "プログラミング", "Web開発", "データベース", "デザイン", "マーケティング",
  "セキュリティ", "AI・機械学習", "モバイル開発", "インフラ", "プロジェクト管理"
]

tags_data = [
  "Ruby", "Rails", "JavaScript", "React", "Vue.js", "Node.js", "Python",
  "SQL", "PostgreSQL", "MySQL", "HTML", "CSS", "Bootstrap", "Git",
  "Docker", "AWS", "セキュリティ", "API", "テスト", "アジャイル"
]

comment_texts = [
  "とても参考になりました！", "詳しい解説をありがとうございます。",
  "実際に試してみたいと思います。", "素晴らしい内容ですね。",
  "もう少し詳しく教えていただけますか？", "これは有用な情報ですね。",
  "経験豊富な方のアドバイスは貴重です。", "次回の記事も楽しみにしています。",
  "質問があります。", "別の方法もあるのでしょうか？",
  "実装してみました！", "続編を期待しています。",
  "同じような経験があります。", "別の視点からの意見です。",
  "実際に使ってみて良かったです。", "初心者にも分かりやすい説明でした。"
]

# プログレス管理用のミューテックス
progress_mutex = Mutex.new
total_progress = { completed: 0, total: 0 }

# プログレス表示用メソッド
def update_progress(progress_mutex, total_progress, completed_count, model_name, elapsed_time)
  progress_mutex.synchronize do
    total_progress[:completed] += completed_count
    progress_percent = (total_progress[:completed].to_f / total_progress[:total] * 100).round(1)
    puts "[#{Time.current.strftime('%H:%M:%S')}] #{model_name} +#{completed_count}件 " +
         "(総計: #{total_progress[:completed]}件, #{progress_percent}%, 経過時間: #{elapsed_time.round(1)}秒)"
  end
end

# バッチサイズ（小規模なので調整）
BATCH_SIZE = 100

# カテゴリーとタグを事前作成（シングルスレッド）
puts "カテゴリーとタグを作成中..."
categories = categories_data.map { |name| Category.create!(name: name) }
tags = tags_data.map { |name| Tag.create!(name: name) }

# データ件数設定（総計5000件）
user_count = 50        # ユーザー
post_count = 3000       # 投稿（メイン）
comment_count = 1000    # コメント
like_count = 500        # いいね
post_tag_count = 400    # 投稿タグ

total_progress[:total] = user_count + post_count + comment_count + like_count + post_tag_count

puts "作成予定データ："
puts "- ユーザー: #{user_count}件"
puts "- カテゴリー: #{categories.length}件"
puts "- タグ: #{tags.length}件"
puts "- 投稿: #{post_count}件"
puts "- コメント: #{comment_count}件"
puts "- いいね: #{like_count}件"
puts "- 投稿タグ: #{post_tag_count}件"
puts "- 総計: #{total_progress[:total]}件\n"

# マルチスレッドでユーザーを作成
puts "マルチスレッドでユーザーを作成中（#{user_count}件）..."
user_batches = (user_count.to_f / BATCH_SIZE).ceil
batches_per_thread = (user_batches.to_f / THREAD_COUNT).ceil

threads = []
THREAD_COUNT.times do |thread_id|
  threads << Thread.new do
    start_batch = thread_id * batches_per_thread
    end_batch = [start_batch + batches_per_thread, user_batches].min

    (start_batch...end_batch).each do |batch|
      users_data = []
      BATCH_SIZE.times do |i|
        index = batch * BATCH_SIZE + i
        break if index >= user_count

        name = "#{japanese_names.sample}#{index + 1}"
        email = "user#{index + 1}@example.com"

        users_data << {
          name: name,
          email: email,
          encrypted_password: BCrypt::Password.create("password123"),
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      next if users_data.empty?

      User.insert_all(users_data)
      update_progress(progress_mutex, total_progress, users_data.size, "ユーザー", Time.current - start_time)
    end
  end
end

threads.each(&:join)
puts "ユーザー作成完了: #{User.count}件\n"

# ユーザーIDとカテゴリーIDを取得
user_ids = User.pluck(:id)
category_ids = Category.pluck(:id)

# マルチスレッドで投稿を作成
puts "マルチスレッドで投稿を作成中（#{post_count}件）..."
post_batches = (post_count.to_f / BATCH_SIZE).ceil
batches_per_thread = (post_batches.to_f / THREAD_COUNT).ceil

threads = []
THREAD_COUNT.times do |thread_id|
  threads << Thread.new do
    start_batch = thread_id * batches_per_thread
    end_batch = [start_batch + batches_per_thread, post_batches].min

    (start_batch...end_batch).each do |batch|
      posts_data = []
      BATCH_SIZE.times do |i|
        index = batch * BATCH_SIZE + i
        break if index >= post_count

        title = "#{post_titles.sample} #{index + 1}"
        content = "#{post_contents.sample}\n\n"
        content += "具体的な内容については、以下の点が重要です：\n\n"
        content += "1. 基本的な概念の理解\n"
        content += "2. 実践的なアプローチ\n"
        content += "3. トラブルシューティング\n"
        content += "4. パフォーマンスの最適化\n\n"
        content += "実際の開発現場では、これらの要素を総合的に考慮する必要があります。"

        posts_data << {
          title: title,
          content: content,
          user_id: user_ids.sample,
          category_id: category_ids.sample,
          created_at: rand(30.days).seconds.ago,
          updated_at: Time.current
        }
      end

      next if posts_data.empty?

      Post.insert_all(posts_data)
      update_progress(progress_mutex, total_progress, posts_data.size, "投稿", Time.current - start_time)
    end
  end
end

threads.each(&:join)
puts "投稿作成完了: #{Post.count}件\n"

# 投稿IDを取得
post_ids = Post.pluck(:id)
tag_ids = Tag.pluck(:id)

# マルチスレッドでコメントを作成
puts "マルチスレッドでコメントを作成中（#{comment_count}件）..."
comment_batches = (comment_count.to_f / BATCH_SIZE).ceil
batches_per_thread = (comment_batches.to_f / THREAD_COUNT).ceil

threads = []
THREAD_COUNT.times do |thread_id|
  threads << Thread.new do
    start_batch = thread_id * batches_per_thread
    end_batch = [start_batch + batches_per_thread, comment_batches].min

    (start_batch...end_batch).each do |batch|
      comments_data = []
      BATCH_SIZE.times do |i|
        index = batch * BATCH_SIZE + i
        break if index >= comment_count

        comments_data << {
          content: comment_texts.sample,
          user_id: user_ids.sample,
          post_id: post_ids.sample,
          created_at: rand(15.days).seconds.ago,
          updated_at: Time.current
        }
      end

      next if comments_data.empty?

      Comment.insert_all(comments_data)
      update_progress(progress_mutex, total_progress, comments_data.size, "コメント", Time.current - start_time)
    end
  end
end

threads.each(&:join)
puts "コメント作成完了: #{Comment.count}件\n"

# マルチスレッドでいいねを作成
puts "マルチスレッドでいいねを作成中（#{like_count}件）..."
like_batches = (like_count.to_f / BATCH_SIZE).ceil
batches_per_thread = (like_batches.to_f / THREAD_COUNT).ceil

threads = []
THREAD_COUNT.times do |thread_id|
  threads << Thread.new do
    start_batch = thread_id * batches_per_thread
    end_batch = [start_batch + batches_per_thread, like_batches].min

    (start_batch...end_batch).each do |batch|
      likes_data = []
      BATCH_SIZE.times do |i|
        index = batch * BATCH_SIZE + i
        break if index >= like_count

        likes_data << {
          user_id: user_ids.sample,
          post_id: post_ids.sample,
          created_at: rand(15.days).seconds.ago,
          updated_at: Time.current
        }
      end

      next if likes_data.empty?

      begin
        Like.insert_all(likes_data, unique_by: [:user_id, :post_id])
        update_progress(progress_mutex, total_progress, likes_data.size, "いいね", Time.current - start_time)
      rescue ActiveRecord::RecordNotUnique
        update_progress(progress_mutex, total_progress, likes_data.size, "いいね(重複除外)", Time.current - start_time)
      end
    end
  end
end

threads.each(&:join)
puts "いいね作成完了: #{Like.count}件\n"

# マルチスレッドで投稿タグを作成
puts "マルチスレッドで投稿タグを作成中（#{post_tag_count}件）..."
post_tag_batches = (post_tag_count.to_f / BATCH_SIZE).ceil
batches_per_thread = (post_tag_batches.to_f / THREAD_COUNT).ceil

threads = []
THREAD_COUNT.times do |thread_id|
  threads << Thread.new do
    start_batch = thread_id * batches_per_thread
    end_batch = [start_batch + batches_per_thread, post_tag_batches].min

    (start_batch...end_batch).each do |batch|
      post_tags_data = []
      BATCH_SIZE.times do |i|
        index = batch * BATCH_SIZE + i
        break if index >= post_tag_count

        post_tags_data << {
          post_id: post_ids.sample,
          tag_id: tag_ids.sample,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      next if post_tags_data.empty?

      begin
        PostTag.insert_all(post_tags_data, unique_by: [:post_id, :tag_id])
        update_progress(progress_mutex, total_progress, post_tags_data.size, "投稿タグ", Time.current - start_time)
      rescue ActiveRecord::RecordNotUnique
        update_progress(progress_mutex, total_progress, post_tags_data.size, "投稿タグ(重複除外)", Time.current - start_time)
      end
    end
  end
end

threads.each(&:join)
puts "投稿タグ作成完了: #{PostTag.count}件\n"

end_time = Time.current
total_time = end_time - start_time

puts "\n" + "="*60
puts "マルチスレッドサンプルデータ作成が完了しました！"
puts "="*60
puts "使用スレッド数: #{THREAD_COUNT}"
puts "作成されたデータ："
puts "- ユーザー: #{User.count}件"
puts "- カテゴリー: #{Category.count}件"
puts "- タグ: #{Tag.count}件"
puts "- 投稿: #{Post.count}件"
puts "- コメント: #{Comment.count}件"
puts "- いいね: #{Like.count}件"
puts "- 投稿タグ: #{PostTag.count}件"

total = User.count + Category.count + Tag.count + Post.count + Comment.count + Like.count + PostTag.count
puts "-" * 60
puts "総合計: #{total}件"
puts "処理時間: #{total_time.round(2)}秒"

# パフォーマンス統計
records_per_second = (total / total_time).round(2)
puts "処理速度: #{records_per_second}件/秒"
puts "="*60