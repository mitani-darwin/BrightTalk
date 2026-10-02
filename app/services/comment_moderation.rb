# コメント本文の誹謗中傷チェック
# config/comment_ng_words.yml の NG ワードを含むコメントを拒否する（外部サービスは使わない）
class CommentModeration
  NG_WORDS_PATH = Rails.root.join("config/comment_ng_words.yml")

  # 照合用に正規化する（全角/半角の統一、小文字化、カタカナ→ひらがな、空白・記号の除去）
  def self.normalize(text)
    text.to_s.unicode_normalize(:nfkc).downcase.tr("ァ-ン", "ぁ-ん").gsub(/[\s\p{P}\p{S}]/, "")
  end

  def self.ng_words
    @ng_words ||= YAML.load_file(NG_WORDS_PATH).fetch("words").map { |word| normalize(word) }.reject(&:empty?).freeze
  end

  def initialize(ng_words: self.class.ng_words)
    @ng_words = ng_words
  end

  # NG ワードを含むか
  def abusive?(content)
    normalized = self.class.normalize(content)
    @ng_words.any? { |word| normalized.include?(word) }
  end
end
