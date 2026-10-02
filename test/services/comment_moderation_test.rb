require "test_helper"

class CommentModerationTest < ActiveSupport::TestCase
  def setup
    @moderation = CommentModeration.new
  end

  test "NG ワードを含むコメントを検出すること" do
    assert @moderation.abusive?("お前なんか死ね")
    assert @moderation.abusive?("こんな記事を書くやつは消えろ")
  end

  test "表記ゆれ（カタカナ・半角・空白・記号）を吸収して NG ワードを検出すること" do
    [ "キモい", "ｷﾓｲ", "き も い", "死・ね", "マジでキモい!!" ].each do |content|
      assert @moderation.abusive?(content), "#{content} を検出できるべきです"
    end
  end

  test "NG ワードを部分に含むだけの普通の言葉は検出しないこと" do
    [ "カスタムフックの解説が分かりやすかったです", "ゴミ箱のアイコンが見つかりませんでした", "馬鹿にならない費用ですね" ].each do |content|
      assert_not @moderation.abusive?(content), "#{content} は許可されるべきです"
    end
  end

  test "記事内容への批判は検出しないこと" do
    assert_not @moderation.abusive?("この手順は Rails 8 では動かないと思います。説明が古いのでは？")
  end

  test "空のコメントは検出しないこと" do
    assert_not @moderation.abusive?("")
    assert_not @moderation.abusive?(nil)
  end
end
