# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://brighttalk.example.com"
SitemapGenerator::Sitemap.public_path = 'tmp/'
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  # Add static pages
  add root_path, priority: 1.0, changefreq: 'daily'

  # Add all published posts
  Post.published_posts.find_each do |post|
    add post_path(post), 
        priority: 0.8, 
        changefreq: 'weekly',
        lastmod: post.updated_at
  end

  # Add all categories with posts
  Category.with_posts.find_each do |category|
    add posts_path(category_id: category.id),
        priority: 0.6,
        changefreq: 'weekly',
        lastmod: category.updated_at
  end

  # Add categories index
  add categories_path, priority: 0.5, changefreq: 'weekly'
end