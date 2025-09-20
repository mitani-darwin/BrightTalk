xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "BrightTalk"
    xml.description "BrightTalkは知識とアイデアを共有するプラットフォームです。"
    xml.link root_url
    xml.language "ja"
    xml.lastBuildDate @posts.first&.updated_at&.rfc2822
    xml.pubDate @posts.first&.created_at&.rfc2822
    xml.ttl "60"

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description truncate(strip_tags(post.content_as_html), length: 300)
        xml.link post_url(post)
        xml.guid post_url(post)
        xml.pubDate post.created_at.rfc2822
        xml.author "#{post.user.email} (#{post.user.name})" if post.user
        xml.category post.category.name if post.category
        
        # Add tags as additional categories
        post.tags.each do |tag|
          xml.category tag.name
        end
      end
    end
  end
end