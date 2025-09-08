#!/usr/bin/env ruby
# Test script to verify new draft validation requirements

require_relative "config/onfig/environment"

# Find a test user (create one if needed)
user = User.first
if user.nil?
  puts "No users found. Please create a user first."
  exit 1
end

puts "=== Testing new draft validation requirements ==="

# Test 1: Draft saving with only title and content (should succeed)
puts "\n1. Testing draft save with only title and content..."
post1 = user.posts.build(
  title: "Test Draft Title",
  content: "Test draft content",
  status: "draft"
  # Purposely omitting purpose, target_audience, and category_id
)

if post1.save
  puts "✅ SUCCESS: Draft saved with only title and content"
  puts "   Post ID: #{post1.id}"
  puts "   Status: #{post1.status}"
else
  puts "❌ FAILED: Draft save failed unexpectedly"
  puts "   Errors: #{post1.errors.full_messages.join(', ')}"
end

# Test 2: Draft saving without title (should fail)
puts "\n2. Testing draft save without title..."
post2 = user.posts.build(
  content: "Test content without title",
  status: "draft"
)

if post2.save
  puts "❌ UNEXPECTED: Draft saved without title"
else
  puts "✅ SUCCESS: Draft correctly failed without title"
  puts "   Errors: #{post2.errors.full_messages.join(', ')}"
end

# Test 3: Draft saving without content (should fail)
puts "\n3. Testing draft save without content..."
post3 = user.posts.build(
  title: "Test title without content",
  status: "draft"
)

if post3.save
  puts "❌ UNEXPECTED: Draft saved without content"
else
  puts "✅ SUCCESS: Draft correctly failed without content"
  puts "   Errors: #{post3.errors.full_messages.join(', ')}"
end

# Test 4: Publishing without all required fields (should fail)
puts "\n4. Testing publish with missing required fields..."
post4 = user.posts.build(
  title: "Test Publish Title",
  content: "Test publish content",
  status: "published"
  # Missing purpose, target_audience, and category_id
)

if post4.save
  puts "❌ UNEXPECTED: Published without all required fields"
else
  puts "✅ SUCCESS: Publish correctly failed validation"
  puts "   Errors: #{post4.errors.full_messages.join(', ')}"
end

# Test 5: Publishing with all required fields (should succeed)
puts "\n5. Testing publish with all required fields..."
default_category = Category.first || Category.create!(name: "テストカテゴリー")
post5 = user.posts.build(
  title: "Complete Test Post",
  content: "Complete test content",
  purpose: "Test purpose",
  target_audience: "Test audience",
  category_id: default_category.id,
  status: "published"
)

if post5.save
  puts "✅ SUCCESS: Published with all required fields"
  puts "   Post ID: #{post5.id}"
  puts "   Status: #{post5.status}"
else
  puts "❌ FAILED: Publish failed unexpectedly"
  puts "   Errors: #{post5.errors.full_messages.join(', ')}"
end

# Clean up
[ post1, post2, post3, post4, post5 ].each do |post|
  post.destroy if post&.persisted?
end

puts "\n=== Test completed ==="
