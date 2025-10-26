#!/usr/bin/env ruby

puts "Testing drafts functionality issues..."

# Start Rails console to test the functionality
system("cd /Users/mitani/git/BrightTalk && rails console -e development << 'EOF'

# Check if we have any draft posts
user = User.first
if user.nil?
  puts "No users found - creating test user"
  user = User.create!(
    email: "test@example.com",
    password: "password123",
    password_confirmation: "password123",
    name: "Test User"
  )
end

# Check for draft posts
draft_posts = user.posts.draft
puts "Found #{draft_posts.count} draft posts"

if draft_posts.count == 0
  puts "Creating test draft posts..."
  3.times do |i|
    user.posts.create!(
      title: "Test Draft #{i + 1}",
      content: "This is test content for draft #{i + 1}",
      status: :draft
    )
  end
  puts "Created 3 test draft posts"
end

puts "Draft posts ready for testing"
exit

EOF")

puts "Test setup complete. Now testing in browser:"
puts "1. Navigate to http://localhost:3000/posts/drafts"
puts "2. Try clicking 'すべて選択' - checkboxes should get checked"
puts "3. Try clicking '選択した下書きを削除' - should show confirmation dialog"