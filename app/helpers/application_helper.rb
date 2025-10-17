module ApplicationHelper
  # メタタグとOGPタグのヘルパーメソッド
  def page_title(title = nil)
    base_title = "BrightTalk"
    if title.present?
      "#{title} | #{base_title}"
    else
      base_title
    end
  end

  def page_description(description = nil)
    description.presence || "BrightTalkは知識とアイデアを共有するプラットフォームです。"
  end

  def page_og_image(image_url = nil)
    image_url.presence || asset_url('og-default.png')
  rescue
    nil
  end

  def meta_tags_for_post(post)
    return {} unless post

    {
      title: post.og_title.presence || post.title,
      description: post.meta_description.presence || post.og_description.presence || truncate(strip_tags(post.content), length: 160),
      og_title: post.og_title.presence || post.title,
      og_description: post.og_description.presence || post.meta_description.presence || truncate(strip_tags(post.content), length: 200),
      og_image: post.og_image.presence || (post.images.attached? ? url_for(post.images.first) : nil),
      og_url: post_url(post),
      og_type: 'article'
    }
  rescue
    {}
  end

  def render_meta_tags(tags = {})
    meta_tags = []
    
    meta_tags << tag.meta(name: "description", content: tags[:description]) if tags[:description]
    meta_tags << tag.meta(property: "og:title", content: tags[:og_title]) if tags[:og_title]
    meta_tags << tag.meta(property: "og:description", content: tags[:og_description]) if tags[:og_description]
    meta_tags << tag.meta(property: "og:image", content: tags[:og_image]) if tags[:og_image]
    meta_tags << tag.meta(property: "og:url", content: tags[:og_url]) if tags[:og_url]
    meta_tags << tag.meta(property: "og:type", content: tags[:og_type]) if tags[:og_type]
    meta_tags << tag.meta(property: "og:site_name", content: "BrightTalk")
    meta_tags << tag.meta(name: "twitter:card", content: "summary_large_image")
    meta_tags << tag.meta(name: "twitter:title", content: tags[:og_title]) if tags[:og_title]
    meta_tags << tag.meta(name: "twitter:description", content: tags[:og_description]) if tags[:og_description]
    meta_tags << tag.meta(name: "twitter:image", content: tags[:og_image]) if tags[:og_image]
    
    safe_join(meta_tags.compact, "\n")
  end

  # ビューから安全にiOSアプリ判定を呼び出すためのヘルパー
  def ios_app_request?
    controller.respond_to?(:ios_app_request?) && controller.send(:ios_app_request?)
  end
end
