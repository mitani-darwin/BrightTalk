#!/usr/bin/env ruby
# Test script to verify draft saving without purpose field

require_relative 'config/onfig/environment'

# Find a test user (create one if needed)
user = User.first
if user.nil?
  puts "No users found. Please create a user first."
  exit 1
end

puts "Testing draft save without purpose field..."

# Create a post without purpose field
post = user.posts.build(
  title: "Test Draft Post",
  content: "This is test content for draft saving",
  status: "draft"
  # Note: purposely omitting purpose, target_audience, and category_id
)

if post.save
  puts "✅ SUCCESS: Draft saved without purpose field"
  puts "   Post ID: #{post.id}"
  puts "   Status: #{post.status}"
  puts "   Purpose: '#{post.purpose}' (empty is expected)"
else
  puts "❌ FAILED: Draft save failed"
  puts "   Errors: #{post.errors.full_messages.join(', ')}"
end

# Test publishing the same post (should fail validation)
puts "\nTesting publish with missing required fields..."
post.status = "published"

if post.save
  puts "❌ UNEXPECTED: Post published without required fields"
else
  puts "✅ SUCCESS: Publish correctly failed validation"
  puts "   Errors: #{post.errors.full_messages.join(', ')}"
end

# Clean up
post.destroy if post.persisted?
puts "\nTest completed."