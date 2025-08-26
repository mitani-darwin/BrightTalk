module PostsHelper
  require 'cgi'

  # Convert Markdown image syntax to HTML img tags
  def format_content_with_images(content, post = nil)
    return '' if content.blank?

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

    # Convert Markdown image syntax ![alt](url) to HTML img tags
    formatted_content = content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
      alt_text = $1
      image_url = $2

      # Handle attachment: URLs (convert to proper Rails attachment URLs)
      normalized_url = image_url.to_s.strip
      if normalized_url.start_with?('attachment:')
        # Extract and normalize filename from attachment URL
        raw = normalized_url.sub(/^attachment:/, '')
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

    # Apply simple_format to handle line breaks while preserving HTML
    simple_format(formatted_content, {}, sanitize: false).html_safe
  end

  # Strip media placeholders (images/videos) from content for index excerpts
  # - Removes Markdown images: ![alt](...)
  # - Removes in-text video placeholders like [動画 foo](attachment:bar)
  # - Also strips any attachment: style links used for media
  def strip_media_from_content(content)
    return '' if content.blank?
    text = content.dup
    # Remove markdown image syntax
    text.gsub!(/!\[[^\]]*\]\([^)]*\)/, '')
    # Remove [動画 ...](attachment:...) links
    text.gsub!(/\[\s*動画[^\]]*\]\(attachment:[^)]*\)/, '')
    # Optionally remove any other attachment: links that might remain
    text.gsub!(/\[[^\]]*\]\(attachment:[^)]*\)/, '')
    # Collapse multiple spaces and newlines after removals
    text = text.gsub(/\n{3,}/, "\n\n").squeeze(' ')
    text.strip
  end
end
