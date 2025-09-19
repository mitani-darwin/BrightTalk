namespace :db do
  desc "Generate slugs for existing users and posts"
  task generate_slugs: :environment do
    puts "Generating slugs for existing users..."
    User.find_each do |user|
      user.slug = nil
      user.save!
      puts "Generated slug for user: #{user.name} -> #{user.slug}"
    end

    puts "Generating slugs for existing posts..."
    Post.find_each do |post|
      post.slug = nil
      post.save!
      puts "Generated slug for post: #{post.title} -> #{post.slug}"
    end

    puts "Slug generation completed!"
  end
end
