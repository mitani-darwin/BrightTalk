
# データベースをクリア
Comment.destroy_all
Post.destroy_all
User.destroy_all

puts "データベースをクリアしました"

# ユーザーを作成
users = []

users << User.create!(
  name: "田中太郎",
  email: "tanaka@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "佐藤花子",
  email: "sato@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "山田次郎",
  email: "yamada@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "鈴木美香",
  email: "suzuki@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "高橋健一",
  email: "takahashi@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "伊藤さくら",
  email: "ito@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "渡辺博",
  email: "watanabe@example.com",
  password: "password",
  password_confirmation: "password"
)

users << User.create!(
  name: "中村あやか",
  email: "nakamura@example.com",
  password: "password",
  password_confirmation: "password"
)

puts "#{users.count}人のユーザーを作成しました"

# 記事のテンプレートデータ
article_templates = [
  # プログラミング系
  {
    title: "Ruby on Railsの基礎を学ぼう",
    content: "Ruby on Railsは、Webアプリケーションを効率的に開発するためのフレームワークです。\n\nMVCアーキテクチャを採用し、Convention over Configuration（設定より規約）の原則に基づいて設計されています。\n\n初心者にも優しく、プロダクティブな開発が可能です。",
    category: "プログラミング"
  },
  {
    title: "JavaScriptの非同期処理をマスターする",
    content: "現代のWeb開発において、JavaScriptの非同期処理は必須のスキルです。\n\nPromise、async/awaitを使いこなすことで、より読みやすく保守しやすいコードが書けるようになります。\n\nFetch APIを使ったHTTPリクエストの例も含めて解説します。",
    category: "プログラミング"
  },
  {
    title: "Pythonで始めるデータ分析",
    content: "Pythonは、データ分析の分野で最も人気のあるプログラミング言語の一つです。\n\nPandas、NumPy、Matplotlibなどのライブラリを使って、効率的にデータを処理・可視化できます。\n\n実際のデータセットを使った分析例も紹介します。",
    category: "プログラミング"
  },
  {
    title: "React Hooksの活用法",
    content: "React Hooksは、関数コンポーネントでstate管理や副作用を扱うための強力な機能です。\n\nuseState、useEffect、useContextなどの基本的なHooksから、カスタムHooksの作成まで詳しく解説します。\n\nパフォーマンス最適化のテクニックも紹介します。",
    category: "プログラミング"
  },
  {
    title: "Dockerを使った開発環境構築",
    content: "Dockerを使うことで、一貫性のある開発環境を簡単に構築できます。\n\nDockerfileの書き方から、docker-composeを使った複数コンテナの管理まで、実践的な内容をカバーします。\n\n本番環境へのデプロイ戦略についても触れます。",
    category: "プログラミング"
  },
  # テクノロジー系
  {
    title: "AIと機械学習の最新動向",
    content: "人工知能と機械学習の技術は急速に発展しています。\n\nChatGPTやStable Diffusionなどの生成AIから、自動運転技術まで、様々な分野での応用が進んでいます。\n\n今後の展望と課題について考察します。",
    category: "テクノロジー"
  },
  {
    title: "クラウドコンピューティングの基礎",
    content: "AWS、Azure、Google Cloudなどのクラウドサービスが、現代のIT業界を支えています。\n\nIaaS、PaaS、SaaSの違いから、セキュリティ、コスト最適化まで幅広く解説します。\n\n実際の導入事例も紹介します。",
    category: "テクノロジー"
  },
  {
    title: "5Gがもたらす変革",
    content: "5G通信技術の普及により、IoT、AR/VR、自動運転などの分野で革新的なサービスが可能になります。\n\n低遅延、高速通信、大容量接続の特徴を活かした新しいビジネスモデルが生まれています。\n\n今後の社会への影響を考えます。",
    category: "テクノロジー"
  },
  # ライフスタイル系
  {
    title: "リモートワークを成功させるコツ",
    content: "リモートワークが普及する中、効率的な働き方を身につけることが重要です。\n\n適切な環境作り、時間管理、コミュニケーション術など、実践的なアドバイスをまとめました。\n\nワークライフバランスの保ち方についても触れます。",
    category: "ライフスタイル"
  },
  {
    title: "健康的な食生活のすすめ",
    content: "忙しい現代人にとって、バランスの取れた食事を心がけることは簡単ではありません。\n\n栄養素の基礎知識から、手軽にできる健康レシピまで紹介します。\n\n食事と運動の組み合わせで、より健康的な生活を目指しましょう。",
    category: "ライフスタイル"
  },
  {
    title: "ミニマリズムの実践方法",
    content: "必要最小限のものだけで生活するミニマリズムが注目されています。\n\n物の整理方法から、心の整理まで、シンプルな生活の始め方を解説します。\n\n環境にも家計にも優しいライフスタイルを提案します。",
    category: "ライフスタイル"
  },
  # ビジネス系
  {
    title: "スタートアップの成功法則",
    content: "多くのスタートアップが失敗する中、成功する企業には共通の特徴があります。\n\n市場調査、プロダクト開発、資金調達、チーム作りなど、各段階でのポイントを解説します。\n\n実際の成功事例から学べる教訓も紹介します。",
    category: "ビジネス"
  },
  {
    title: "デジタルマーケティング戦略",
    content: "デジタル時代のマーケティングは、従来の手法とは大きく異なります。\n\nSNS活用、SEO対策、コンテンツマーケティングなど、効果的な手法を体系的に説明します。\n\nデータ分析に基づいた改善サイクルの回し方も解説します。",
    category: "ビジネス"
  },
  # 趣味・エンタメ系
  {
    title: "写真撮影のテクニック向上術",
    content: "スマートフォンの普及により、誰でも手軽に写真を撮れるようになりました。\n\n構図の基本から、光の使い方、編集テクニックまで、より魅力的な写真を撮るコツを紹介します。\n\n風景、ポートレート、マクロなど、ジャンル別のアドバイスも含まれます。",
    category: "趣味・エンタメ"
  },
  {
    title: "読書習慣を身につける方法",
    content: "読書は知識を深め、視野を広げる素晴らしい習慣です。\n\n忙しい日常の中で読書時間を確保する方法や、効率的な読書術を紹介します。\n\nジャンル別のおすすめ本リストも掲載しています。",
    category: "趣味・エンタメ"
  }
]

# 追加のタイトルとコンテンツのパターン
additional_titles = [
  "効率的な学習方法とは", "時間管理術の極意", "コミュニケーション能力向上のコツ",
  "創造性を高める習慣", "ストレス解消法", "投資の基礎知識",
  "副業を始める前に知っておくべきこと", "環境問題と個人の取り組み", "旅行を安全に楽しむ方法",
  "料理初心者向けレシピ", "ガーデニングの始め方", "ペットとの暮らし",
  "音楽が人生に与える影響", "映画から学ぶ人生哲学", "スポーツとメンタルヘルス",
  "アートの楽しみ方", "言語学習のコツ", "歴史から学ぶ教訓",
  "科学の面白さ", "哲学入門", "心理学の応用",
  "経済の基本原理", "政治への関心の持ち方", "社会問題への向き合い方",
  "教育の未来", "医療技術の進歩", "宇宙探査の最前線",
  "気候変動対策", "持続可能な社会作り", "文化の多様性",
  "ファッションと自己表現", "美容と健康", "インテリアデザイン",
  "家計管理のコツ", "キャリアプランニング", "転職成功の秘訣",
  "起業家精神", "リーダーシップ論", "チームワークの重要性",
  "イノベーションの創出", "問題解決思考", "批判的思考力",
  "データサイエンス入門", "ブロックチェーン技術", "IoTの可能性",
  "VR・ARの活用", "量子コンピューター", "バイオテクノロジー",
  "再生可能エネルギー", "スマートシティ", "自動運転の未来",
  "ゲーム産業の変化", "eスポーツの発展", "配信文化の影響",
  "SNSとの付き合い方", "デジタルデトックス", "オンライン学習",
  "テレワークツール", "サイバーセキュリティ", "プライバシー保護",
  "アジャイル開発", "DevOps実践", "コードレビューの効果",
  "オープンソース貢献", "技術コミュニティ", "メンターシップ",
  "プレゼンテーション術", "ネゴシエーション", "クリエイティブ思考",
  "マインドフルネス", "瞑想の効果", "ヨガと健康",
  "アウトドア活動", "都市探索", "文化体験",
  "グルメ探訪", "カフェ文化", "地域の魅力発見",
  "季節の楽しみ方", "伝統文化継承", "現代アート鑑賞",
  "パフォーマンス向上", "集中力アップ", "記憶力強化",
  "情報収集術", "ネットワーキング", "メンタルヘルス"
]

content_templates = [
  "この分野について詳しく調べた結果、興味深い発見がありました。\n\n実際の経験を通して学んだことを、具体例とともに紹介します。\n\n皆さんの参考になれば幸いです。",
  "最近注目されているこのトピックについて、専門家の意見と実際のデータを基に分析してみました。\n\n将来的な展望も含めて、分かりやすく解説します。\n\n実践的なアドバイスも盛り込んでいます。",
  "多くの人が関心を持っているこの問題について、様々な角度から検討してみました。\n\n基礎知識から応用まで、段階的に説明していきます。\n\n実際に試してみた結果も報告します。",
  "この分野の基本的な考え方から、最新の動向まで幅広くカバーしています。\n\n初心者の方にも分かりやすいように、図解や具体例を多用しました。\n\n専門家へのインタビューも含まれています。"
]

categories = ["プログラミング", "テクノロジー", "ライフスタイル", "ビジネス", "趣味・エンタメ", "学習・教育", "健康・美容", "旅行・グルメ"]

puts "記事を作成中..."

# 100件の記事を作成
100.times do |i|
  # 最初の15件は詳細なテンプレートを使用
  if i < article_templates.length
    template = article_templates[i]
    title = template[:title]
    content = template[:content]
    category = template[:category]
  else
    # 残りは追加タイトルとランダムコンテンツを使用
    title_index = (i - article_templates.length) % additional_titles.length
    title = additional_titles[title_index]
    content = content_templates.sample
    category = categories.sample
  end

  # ランダムにユーザーを選択
  user = users.sample

  # 投稿を作成
  post = Post.create!(
    title: "#{title} - #{category}編",
    content: content,
    user: user
  )

  # 60%の確率で画像を添付
  if rand < 0.6
    begin
      require 'open-uri'

      # カテゴリに応じた画像を取得
      image_seed = case category
                   when "プログラミング", "テクノロジー"
                     rand(1000..1999)
                   when "ライフスタイル", "健康・美容"
                     rand(2000..2999)
                   when "ビジネス", "学習・教育"
                     rand(3000..3999)
                   when "趣味・エンタメ", "旅行・グルメ"
                     rand(4000..4999)
                   else
                     rand(5000..5999)
                   end

      image_url = "https://picsum.photos/800/600?random=#{image_seed}"
      downloaded_image = URI.open(image_url)

      post.image.attach(
        io: downloaded_image,
        filename: "article_image_#{i + 1}.jpg",
        content_type: "image/jpeg"
      )

    rescue => e
      puts "画像の添付に失敗しました (記事#{i + 1}): #{e.message}"
    end
  end

  # 投稿日時をランダムに設定（過去3ヶ月以内）
  random_time = rand(3.months.ago..Time.current)
  post.update_columns(created_at: random_time, updated_at: random_time)

  print "." if (i + 1) % 10 == 0
end

puts "\n100件の記事を作成しました"

# コメントを作成
puts "コメントを作成中..."

comment_templates = [
  "とても参考になりました！", "素晴らしい記事ですね", "勉強になります",
  "実際に試してみます", "興味深い内容でした", "もっと詳しく知りたいです",
  "同感です", "これは役立ちそう", "ありがとうございます",
  "続編を期待しています", "シェアさせていただきます", "保存しました",
  "具体例があって分かりやすい", "初心者にも優しい内容", "専門的で勉強になる",
  "実体験に基づいていて信頼できる", "図解が分かりやすい", "データが豊富で参考になる"
]

# 各記事に0-5個のコメントをランダムに追加
Post.all.each do |post|
  comment_count = rand(0..5)
  comment_count.times do
    user = users.sample
    content = comment_templates.sample

    comment = Comment.create!(
      content: content,
      user: user,
      post: post
    )

    # コメント日時を投稿日時以降に設定
    comment_time = rand(post.created_at..Time.current)
    comment.update_columns(created_at: comment_time, updated_at: comment_time)
  end
end

puts "コメントを作成しました"

puts "\n=== シードデータ作成完了 ==="
puts "作成されたデータ:"
puts "- ユーザー: #{User.count}人"
puts "- 投稿: #{Post.count}件"
puts "- コメント: #{Comment.count}件"
puts "- 画像付き投稿: #{Post.joins(:image_attachment).count}件"

# カテゴリ別の投稿数を表示
puts "\nカテゴリ別投稿数:"
categories.each do |category|
  count = Post.where("title LIKE ?", "%#{category}編%").count
  puts "- #{category}: #{count}件"
end