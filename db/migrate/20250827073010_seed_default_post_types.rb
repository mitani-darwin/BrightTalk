class SeedDefaultPostTypes < ActiveRecord::Migration[8.0]
  DEFAULT_TYPES = [
    { name: 'knowledge_sharing', description: '知識共有' },
    { name: 'question',           description: '質問・相談' },
    { name: 'discussion',         description: '議論・討論' },
    { name: 'tutorial',           description: 'チュートリアル・手順' },
    { name: 'experience_sharing', description: '体験談・事例' },
    { name: 'news_update',        description: 'ニュース・更新情報' },
    { name: 'opinion',            description: '意見・考察' }
  ]

  def up
    say_with_time 'Seeding default PostType records' do
      DEFAULT_TYPES.each do |attrs|
        PostType.where(name: attrs[:name]).first_or_create!(description: attrs[:description])
      end
    end
  end

  def down
    say_with_time 'Removing default PostType records (if present)' do
      names = DEFAULT_TYPES.map { |h| h[:name] }
      PostType.where(name: names).delete_all
    end
  end
end
