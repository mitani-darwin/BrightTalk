xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title "BrightTalk"
  xml.subtitle "BrightTalkは知識とアイデアを共有するプラットフォームです。"
  xml.id root_url
  xml.link "href" => root_url
  xml.link "href" => feeds_atom_url, "rel" => "self"
  xml.updated @posts.first&.updated_at&.iso8601
  xml.author do
    xml.name "BrightTalk"
    xml.email "noreply@brighttalk.example.com"
  end

  @posts.each do |post|
    xml.entry do
      xml.title post.title
      xml.link "href" => post_url(post)
      xml.id post_url(post)
      xml.updated post.updated_at.iso8601
      xml.published post.created_at.iso8601
      
      xml.author do
        xml.name post.user.name if post.user
        xml.email post.user.email if post.user
      end
      
      xml.summary truncate(strip_tags(post.content_as_html), length: 300), "type" => "text"
      xml.content post.content_as_html, "type" => "html"
      
      # Add category
      if post.category
        xml.category "term" => post.category.name, "label" => post.category.name
      end
      
      # Add tags as categories
      post.tags.each do |tag|
        xml.category "term" => tag.name, "label" => tag.name
      end
    end
  end
end