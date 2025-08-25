module PostsHelper
  # Convert Markdown image syntax to HTML img tags
  def format_content_with_images(content, post = nil)
    return '' if content.blank?
    
    # Convert Markdown image syntax ![alt](url) to HTML img tags
    formatted_content = content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
      alt_text = $1
      image_url = $2
      
      # Handle attachment: URLs (convert to proper Rails attachment URLs)
      if image_url.start_with?('attachment:')
        # Extract filename from attachment URL
        filename = image_url.gsub('attachment:', '')
        
        # Try to find matching image in post's attachments
        if post&.images&.attached?
          matching_image = post.images.find { |img| img.filename.to_s == filename }
          if matching_image
            actual_url = Rails.application.routes.url_helpers.rails_blob_path(matching_image, only_path: true)
            %Q(<img src="#{ERB::Util.html_escape(actual_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="img-fluid rounded my-3 clickable-image" style="max-width: 100%; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(actual_url)}" data-image-alt="#{ERB::Util.html_escape(alt_text)}" />)
          else
            # Fallback: don't display anything if attachment not found
            ""
          end
        else
          # Fallback: don't display anything if no post or no images
          ""
        end
      else
        # For regular URLs, create proper img tag
        %Q(<img src="#{ERB::Util.html_escape(image_url)}" alt="#{ERB::Util.html_escape(alt_text)}" class="img-fluid rounded my-3 clickable-image" style="max-width: 100%; cursor: pointer;" data-bs-toggle="modal" data-bs-target="#imageModal" data-image-src="#{ERB::Util.html_escape(image_url)}" data-image-alt="#{ERB::Util.html_escape(alt_text)}" />)
      end
    end
    
    # Apply simple_format to handle line breaks while preserving HTML
    simple_format(formatted_content, {}, sanitize: false).html_safe
  end
end
