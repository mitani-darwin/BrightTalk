#!/usr/bin/env ruby

# Test script to reproduce the auto-save validation issue
# This script simulates sending an auto-save request with missing required fields

require 'net/http'
require 'json'
require 'uri'

def test_auto_save_with_missing_fields
  puts "=== Testing Auto-Save with Missing Required Fields ==="
  
  # Simulate auto-save data with missing required fields
  auto_save_data = {
    post: {
      title: "", # Empty title (required field)
      content: "Some partial content...", # Has content
      # Missing: purpose, target_audience, category_id, post_type_id
    }
  }
  
  puts "Test data (missing required fields):"
  puts JSON.pretty_generate(auto_save_data)
  puts "\n"
  
  # Show what the current validation logic should do
  puts "Expected behavior based on Post model validations:"
  puts "- title: presence validation should fail (empty string)"
  puts "- content: presence validation should pass (has content)" 
  puts "- purpose: presence validation should fail (missing)"
  puts "- target_audience: presence validation should fail (missing)"
  puts "- category_id: presence validation should fail (missing)"
  puts "- post_type_id: presence validation should fail (missing)"
  puts "\n"
  
  puts "Current issue:"
  puts "- auto_save method uses @post.update!(safe_params) which enforces validation"
  puts "- Even though auto_save attribute is set, the update! method still validates"
  puts "- The auto_saved_draft? method checks both draft? AND auto_save == true"
  puts "- But the validation bypass only works if the record is already saved as draft"
  puts "\n"
  
  puts "Root cause:"
  puts "- The auto_save attribute is set AFTER the post is created/found"
  puts "- During update!, the auto_save attribute may not be properly set"
  puts "- Need to use update() instead of update!() for auto-save to skip validation errors"
  
  return true
end

# Run the test
if __FILE__ == $0
  test_auto_save_with_missing_fields
end