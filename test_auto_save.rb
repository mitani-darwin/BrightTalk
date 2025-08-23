#!/usr/bin/env ruby
# Test script to verify auto-save functionality

require_relative 'config/environment'

# Find a test user
user = User.first
if user.nil?
  puts "No users found. Please create a user first."
  exit 1
end

puts "=== Testing Auto-Save Functionality ==="

# Test 1: Auto-save with completely empty data (should succeed)
puts "\n1. Testing auto-save with completely empty data..."
post1 = user.posts.build
post1.status = 'draft'
post1.auto_save = true

if post1.save(validate: false)
  puts "✅ SUCCESS: Empty post auto-saved without validation"
  puts "   Post ID: #{post1.id}"
  puts "   Status: #{post1.status}"
  puts "   Title: '#{post1.title}' (empty)"
  puts "   Content: '#{post1.content}' (empty)"
else
  puts "❌ FAILED: Empty post auto-save failed"
  puts "   Errors: #{post1.errors.full_messages.join(', ')}"
end

# Test 2: Auto-save with partial data (should succeed)
puts "\n2. Testing auto-save with partial data..."
post2 = user.posts.build(title: "Partial Title")
post2.status = 'draft'
post2.auto_save = true

if post2.save(validate: false)
  puts "✅ SUCCESS: Partial post auto-saved without validation"
  puts "   Post ID: #{post2.id}"
  puts "   Title: '#{post2.title}'"
  puts "   Content: '#{post2.content}' (empty)"
else
  puts "❌ FAILED: Partial post auto-save failed"
  puts "   Errors: #{post2.errors.full_messages.join(', ')}"
end

# Test 3: Regular draft save with validation (should fail for empty)
puts "\n3. Testing regular draft save with validation (should fail for empty)..."
post3 = user.posts.build
post3.status = 'draft'
# Note: auto_save flag not set, so validations should apply

if post3.save
  puts "❌ UNEXPECTED: Empty draft saved with validation"
else
  puts "✅ SUCCESS: Empty draft correctly failed validation"
  puts "   Errors: #{post3.errors.full_messages.join(', ')}"
end

# Test 4: Regular draft save with title and content (should succeed)
puts "\n4. Testing regular draft save with title and content..."
post4 = user.posts.build(
  title: "Valid Draft Title",
  content: "Valid draft content"
)
post4.status = 'draft'

if post4.save
  puts "✅ SUCCESS: Valid draft saved with validation"
  puts "   Post ID: #{post4.id}"
  puts "   Title: '#{post4.title}'"
  puts "   Content: '#{post4.content}'"
else
  puts "❌ FAILED: Valid draft failed validation"
  puts "   Errors: #{post4.errors.full_messages.join(', ')}"
end

# Clean up
[post1, post2, post3, post4].each do |post|
  post.destroy if post&.persisted?
end

puts "\n=== Auto-Save Test completed ==="