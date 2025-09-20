class SitemapsController < ApplicationController
  def index
    respond_to do |format|
      format.xml do
        # Generate sitemap on-the-fly or serve cached version
        sitemap_path = Rails.root.join('tmp', 'sitemaps', 'sitemap.xml.gz')
        
        if File.exist?(sitemap_path) && File.mtime(sitemap_path) > 1.day.ago
          # Serve cached sitemap if it exists and is less than 1 day old
          send_file sitemap_path, type: 'application/xml', disposition: 'inline'
        else
          # Generate new sitemap
          SitemapGenerator::Interpreter.run
          if File.exist?(sitemap_path)
            send_file sitemap_path, type: 'application/xml', disposition: 'inline'
          else
            render xml: generate_simple_sitemap, content_type: 'application/xml'
          end
        end
      end
    end
  end

  private

  def generate_simple_sitemap
    builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        # Add root URL
        xml.url do
          xml.loc root_url
          xml.lastmod Time.current.iso8601
          xml.changefreq 'daily'
          xml.priority '1.0'
        end

        # Add all published posts
        Post.published_posts.find_each do |post|
          xml.url do
            xml.loc post_url(post)
            xml.lastmod post.updated_at.iso8601
            xml.changefreq 'weekly'
            xml.priority '0.8'
          end
        end

        # Add categories with posts
        Category.with_posts.find_each do |category|
          xml.url do
            xml.loc posts_url(category_id: category.id)
            xml.lastmod category.updated_at.iso8601
            xml.changefreq 'weekly'
            xml.priority '0.6'
          end
        end
      end
    end
    
    builder.to_xml
  end
end