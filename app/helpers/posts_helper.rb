module PostsHelper
  require "cgi"

  # Convert Markdown content to HTML with support for images and videos
  def format_content_with_images(content, post = nil)
    return "" if content.blank?

    # Normalizer to make filename comparisons robust across encodings and Unicode forms
    normalize_name = ->(name) do
      s = name.to_s.strip
      begin
        s = CGI.unescape(s)
      rescue
        # ignore malformed escape sequences
      end
      s = s.unicode_normalize(:nfc) if s.respond_to?(:unicode_normalize)
      s
    end

    # First, process attachment-style media links before Markdown processing
    processed_content = content.dup

    # Convert Markdown image syntax ![alt](url) to HTML img tags
    processed_content = processed_content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
      alt_text = $1
      image_url = $2

      # Handle attachment: URLs (convert to proper Rails attachment URLs)
      normalized_url = image_url.to_s.strip
      if normalized_url.start_with?("attachment:")
        # Extract and normalize filename from attachment URL
        raw = normalized_url.sub(/^attachment:/, "")
        placeholder_name = normalize_name.call(raw)

        # Try to find matching image in post's attachments (robust match)
        if post&.images&.attached?
          matching_image = post.images.find do |img|
            normalize_name.call(img.filename.to_s) == placeholder_name
          end
          if matching_image
            actual_url = Rails.application.routes.url_helpers.rails_blob_path(matching_image, only_path: true)
            %Q(<img src="#{ERB::Util.html_escape(actual_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="img-fluid rounded my-3 clickable-image" style="max-width: 100%; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(actual_url)}" data-image-alt="#{ERB::Util.html_escape(alt_text)}" />)
          else
            # Fallback: keep the original markdown text if not found so user still sees something
            match
          end
        else
          # No post or no images: keep original markdown
          match
        end
      else
        # For regular URLs, create proper img tag
        %Q(<img src="#{ERB::Util.html_escape(image_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="img-fluid rounded my-3 clickable-image" style="max-width: 100%; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(image_url)}" data-image-alt="#{ERB::Util.html_escape(alt_text)}" />)
      end
    end

    # Convert video links [動画 filename](attachment:filename) to HTML video tags
    processed_content = processed_content.gsub(/\[([^\]]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v))\]\(attachment:([^)]+)\)/i) do |match|
      attachment_filename = $1.strip
      normalized_filename = normalize_name.call(attachment_filename)

      # Try to find matching video in post's attachments
      if post&.videos&.attached?
        matching_video = post.videos.find do |vid|
          normalize_name.call(vid.filename.to_s) == normalized_filename
        end

        if matching_video
          video_url = get_cloudfront_video_url(matching_video)
          video_id = "video-#{SecureRandom.hex(8)}"
          %Q(<div class="video-container my-4" data-controller="video-player" data-video-player-src-value="#{ERB::Util.html_escape(video_url)}" data-video-player-type-value="#{ERB::Util.html_escape(matching_video.content_type)}"><video id="#{video_id}" data-video-player-target="video" class="video-js vjs-default-skin" style="width: 100%; max-width: 100%;" preload="metadata"><source src="#{ERB::Util.html_escape(video_url)}" type="#{matching_video.content_type}"><p class="vjs-no-js">Video.jsを有効にするには、<a href="https://videojs.com/html5-video-support/" target="_blank">ブラウザでJavaScriptを有効</a>にしてください。<br>または<a href="#{ERB::Util.html_escape(video_url)}" download>動画をダウンロード</a>してください。</p></video></div>)
        else
          # Fallback: keep the original markdown text if video not found
          match
        end
      else
        # No post or no videos: keep original markdown
        match
      end
    end

    # Apply full Markdown processing using Redcarpet
    renderer = Redcarpet::Render::HTML.new(
      filter_html: false,
      no_links: false,
      no_images: false,
      hard_wrap: true,
      link_attributes: { target: "_blank", rel: "noopener" }
    )

    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      quote: true,
      footnotes: true,
      space_after_headers: true
    )

    # Convert Markdown to HTML
    html_content = markdown.render(processed_content)
    html_content.html_safe
  end

  # Strip media placeholders (images/videos) from content for index excerpts
  # - Removes Markdown images: ![alt](...)
  # - Removes in-text video placeholders like [動画 foo](attachment:bar)
  # - Also strips any attachment: style links used for media
  def strip_media_from_content(content)
    return "" if content.blank?
    text = content.dup
    # Remove markdown image syntax
    text.gsub!(/!\[[^\]]*\]\([^)]*\)/, "")
    # Remove [動画 ...](attachment:...) links
    text.gsub!(/\[\s*動画[^\]]*\]\(attachment:[^)]*\)/, "")
    # Optionally remove any other attachment: links that might remain
    text.gsub!(/\[[^\]]*\]\(attachment:[^)]*\)/, "")
    # Collapse multiple spaces and newlines after removals
    text = text.gsub(/\n{3,}/, "\n\n").squeeze(" ")
    text.strip
  end

  private

  # Get CloudFront URL for video if available, otherwise fallback to s3 URL
  def get_cloudfront_video_url(video_attachment)
    # Check if CloudFront distribution URL is configured
    cloudfront_base_url = Rails.application.credentials.dig(:cloudfront, :distribution_url)

    if cloudfront_base_url.present?
      # Use CloudFront URL for optimized video delivery
      video_key = video_attachment.blob.key
      "#{cloudfront_base_url.chomp('/')}/#{video_key}"
    else
      # Fallback to direct s3/Rails URL
      Rails.application.routes.url_helpers.rails_blob_path(video_attachment, only_path: true)
    end
  end
end
