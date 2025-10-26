#!/usr/bin/env ruby

# Test script to verify current validation behavior and test ordered validation
require_relative 'config/environment'

puts "Testing current validation behavior..."
puts "=" * 50

# Create a test post to check current validation
post = Post.new

# Test validation without any fields
puts "Testing validation with empty post:"
valid = post.valid?
puts "Valid: #{valid}"
puts "Errors: #{post.errors.full_messages}"
puts

# Test field by field to understand current validation order
fields_to_test = [
  { name: 'purpose', value: 'Test purpose', label: '投稿の目的' },
  { name: 'post_type_id', value: 1, label: '投稿タイプ' },
  { name: 'category_id', value: 1, label: 'カテゴリー' },
  { name: 'target_audience', value: 'Test audience', label: '対象読者' },
  { name: 'title', value: 'Test title', label: 'タイトル' }
]

puts "Testing each field individually:"
fields_to_test.each do |field|
  test_post = Post.new
  test_post.send("#{field[:name]}=", field[:value])
  
  valid = test_post.valid?
  puts "#{field[:label]} (#{field[:name]}): Valid=#{valid}, Errors=#{test_post.errors.full_messages}"
end

puts
puts "Current validation requirements identified:"
puts "- Required fields need to be validated in this order:"
puts "  1. 投稿の目的 (purpose)"
puts "  2. 投稿タイプ (post_type_id)" 
puts "  3. カテゴリー (category_id)"
puts "  4. 対象読者 (target_audience)"
puts "  5. タイトル (title)"