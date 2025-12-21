module PostsHelper
  require "cgi"
  def post_title(post)
    post.title.presence || post.name.presence || "無題"
  end

  def post_date(post)
    (post.respond_to?(:published_at) && post.published_at.present? ? post.published_at : nil) || post.created_at
  end

  def post_excerpt(post)
    text = post.respond_to?(:excerpt) ? post.excerpt : nil
    text = post.summary if text.blank? && post.respond_to?(:summary)
    if text.blank?
      body = post.respond_to?(:body) ? post.body : post.respond_to?(:content) ? post.content : nil
      text = strip_tags(body.to_s)
    end
    text.present? ? truncate(text, length: 140) : nil
  end

  def post_thumbnail_url(post)
    url = post.respond_to?(:thumbnail_url) ? post.thumbnail_url : nil
    return url if url.present?

    if post.respond_to?(:image)
      image = post.image
      if image.respond_to?(:attached?) && image.attached?
        return url_for(image)
      elsif image.present? && image.is_a?(String)
        return image
      end
    end

    if post.respond_to?(:images) && post.images.respond_to?(:attached?) && post.images.attached?
      return url_for(post.images.first)
    end

    nil
  end

  def post_body_html(post)
    html = if post.respond_to?(:body_html) && post.body_html.present?
      post.body_html
    elsif post.respond_to?(:body) && post.body.present?
      format_content_with_images_tailwind(post.body, post)
    elsif post.respond_to?(:content) && post.content.present?
      format_content_with_images_tailwind(post.content, post)
    else
      ""
    end
    html.to_s.html_safe
  end

  # Tailwind版: Bootstrap由来のクラスやdata-bsを使わずにHTMLへ変換する
  def format_content_with_images_tailwind(content, post = nil)
    return "" if content.blank?

    normalize_name = ->(name) do
      s = name.to_s.strip
      begin
        s = CGI.unescape(s)
      rescue
      end
      s = s.unicode_normalize(:nfc) if s.respond_to?(:unicode_normalize)
      s
    end

    processed_content = content.dup

    processed_content = processed_content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
      alt_text = $1
      image_url = $2
      normalized_url = image_url.to_s.strip
      if normalized_url.start_with?("attachment:")
        raw = normalized_url.sub(/^attachment:/, "")
        placeholder_name = normalize_name.call(raw)
        if post&.images&.attached?
          matching_image = post.images.find do |img|
            normalize_name.call(img.filename.to_s) == placeholder_name
          end
          if matching_image
            actual_url = Rails.application.routes.url_helpers.rails_blob_path(matching_image, only_path: true)
            %Q(<img src="#{ERB::Util.html_escape(actual_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="my-6 w-full rounded-xl border border-slate-200 shadow-sm" loading="lazy" />)
          else
            match
          end
        else
          match
        end
      else
        %Q(<img src="#{ERB::Util.html_escape(image_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="my-6 w-full rounded-xl border border-slate-200 shadow-sm" loading="lazy" />)
      end
    end

    processed_content = processed_content.gsub(/\[([^\]]*\.(?:mp4|avi|mov|wmv|flv|webm|mkv|m4v))\]\(attachment:([^)]+)\)/i) do |match|
      attachment_filename = $1.strip
      normalized_filename = normalize_name.call(attachment_filename)
      if post&.videos&.attached?
        matching_video = post.videos.find do |vid|
          normalize_name.call(vid.filename.to_s) == normalized_filename
        end

        if matching_video
          video_url = get_cloudfront_video_url(matching_video)
          video_id = "video-#{SecureRandom.hex(8)}"
          %Q(<div class="my-6" data-controller="video-player" data-video-player-src-value="#{ERB::Util.html_escape(video_url)}" data-video-player-type-value="#{ERB::Util.html_escape(matching_video.content_type)}"><video id="#{video_id}" data-video-player-target="video" class="video-js vjs-default-skin w-full rounded-xl overflow-hidden" preload="metadata" crossorigin="anonymous"><source src="#{ERB::Util.html_escape(video_url)}" type="#{matching_video.content_type}"><p class="vjs-no-js">Video.jsを有効にするには、<a href="https://videojs.com/html5-video-support/" target="_blank">ブラウザでJavaScriptを有効</a>にしてください。<br>または<a href="#{ERB::Util.html_escape(video_url)}" download>動画をダウンロード</a>してください。</p></video></div>)
        else
          match
        end
      else
        match
      end
    end

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

    html_content = markdown.render(processed_content)
    begin
      require 'loofah'
      fragment = Loofah.fragment(html_content)
      scrubber = Loofah::Scrubber.new do |node|
        node.remove_attribute('style') if node.respond_to?(:attributes) && node['style']
      end
      fragment.scrub!(scrubber)
      html_content = fragment.to_html
    rescue LoadError
      html_content = html_content.gsub(/\sstyle="[^"]*"/i, '')
    end
    html_content.html_safe
  end

  if defined?(WillPaginate)
    class TailwindPaginationRenderer < WillPaginate::ActionView::LinkRenderer
      def container_attributes
        { class: "inline-flex items-center gap-1 text-sm" }
      end

      def page_number(page)
        if page == current_page
          tag(:span, page, class: "inline-flex min-w-[2.25rem] items-center justify-center rounded-lg border border-brand-600 bg-brand-600 px-3 py-1.5 font-semibold text-white")
        else
          link(page, page, class: "inline-flex min-w-[2.25rem] items-center justify-center rounded-lg border border-slate-200 px-3 py-1.5 text-slate-700 transition hover:border-slate-300 hover:bg-slate-50")
        end
      end

      def gap
        tag(:span, @template.raw("&hellip;"), class: "inline-flex min-w-[2.25rem] items-center justify-center rounded-lg border border-slate-200 px-3 py-1.5 text-slate-400")
      end

      def previous_or_next_page(page, text, classname)
        if page
          link(text, page, class: "inline-flex min-w-[2.25rem] items-center justify-center rounded-lg border border-slate-200 px-3 py-1.5 text-slate-700 transition hover:border-slate-300 hover:bg-slate-50")
        else
          tag(:span, text, class: "inline-flex min-w-[2.25rem] items-center justify-center rounded-lg border border-slate-200 px-3 py-1.5 text-slate-300")
        end
      end
    end
  end

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
            %Q(<img src="#{ERB::Util.html_escape(actual_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="img-fluid rounded my-3 clickable-image cursor-pointer" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(actual_url)}" data-image-alt="#{ERB::Util.html_escape(alt_text)}" />)
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
        %Q(<img src="#{ERB::Util.html_escape(image_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="img-fluid rounded my-3 clickable-image cursor-pointer" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(image_url)}" data-image-alt="#{ERB::Util.html_escape(alt_text)}" />)
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
          %Q(<div class="video-container my-4" data-controller="video-player" data-video-player-src-value="#{ERB::Util.html_escape(video_url)}" data-video-player-type-value="#{ERB::Util.html_escape(matching_video.content_type)}"><video id="#{video_id}" data-video-player-target="video" class="video-js vjs-default-skin w-100" preload="metadata" crossorigin="anonymous"><source src="#{ERB::Util.html_escape(video_url)}" type="#{matching_video.content_type}"><p class="vjs-no-js">Video.jsを有効にするには、<a href="https://videojs.com/html5-video-support/" target="_blank">ブラウザでJavaScriptを有効</a>にしてください。<br>または<a href="#{ERB::Util.html_escape(video_url)}" download>動画をダウンロード</a>してください。</p></video></div>)
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
    begin
      require 'loofah'
      fragment = Loofah.fragment(html_content)
      scrubber = Loofah::Scrubber.new do |node|
        node.remove_attribute('style') if node.respond_to?(:attributes) && node['style']
      end
      fragment.scrub!(scrubber)
      html_content = fragment.to_html
    rescue LoadError
      # Fallback: if Loofah is not available, remove inline style attributes with a best-effort regex
      html_content = html_content.gsub(/\sstyle="[^"]*"/i, '')
    end
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
      # Fallback: ActiveStorageの標準リダイレクトURL（パラメータ最小限で署名ずれを防止）
      Rails.application.routes.url_helpers.rails_storage_redirect_url(
        video_attachment,
        host: Rails.application.config.action_mailer.default_url_options[:host],
        protocol: Rails.application.config.action_mailer.default_url_options[:protocol]
      )
    end
  end
end
