#!/usr/bin/env ruby
# Script to test the fix for RecordNotFound error handling

require_relative 'config/environment'
require 'rails/test_help'

puts "=== Testing the Fix for RecordNotFound Error ==="
puts

# Simulate a controller test environment
class TestPostsController < PostsController
  # Override redirect_to for testing
  def redirect_to(url, options = {})
    puts "✅ Redirect called successfully!"
    puts "   URL: #{url}"
    puts "   Alert: #{options[:alert]}" if options[:alert]
    @redirected = true
    @redirect_url = url
    @redirect_options = options
  end
  
  # Make set_post public for testing
  public :set_post
  
  # Mock params
  def params
    @params ||= ActionController::Parameters.new(id: "aaa-9aba0bf8-0be2-4086-bb80-cedcbf63c061")
  end
  
  def posts_path
    "/posts"
  end
  
  # Check if redirect was called
  def redirected?
    @redirected || false
  end
  
  attr_reader :redirect_url, :redirect_options
end

# Test the fixed set_post method
controller = TestPostsController.new

puts "Testing set_post method with invalid friendly_id..."
puts "Friendly ID: aaa-9aba0bf8-0be2-4086-bb80-cedcbf63c061"
puts

begin
  controller.set_post
  
  if controller.redirected?
    puts "✅ Test passed! Error was handled gracefully."
    puts "   Redirected to: #{controller.redirect_url}"
    puts "   Alert message: #{controller.redirect_options[:alert]}"
  else
    puts "❌ Test failed! No redirect occurred."
  end
  
rescue => e
  puts "❌ Test failed! Exception was not handled:"
  puts "   Error: #{e.class.name}: #{e.message}"
end

puts
puts "=== Testing with valid friendly_id ==="

# Test with valid friendly_id
valid_post = Post.first
if valid_post
  class ValidTestController < TestPostsController
    def params
      @params ||= ActionController::Parameters.new(id: Post.first.friendly_id)
    end
  end
  
  valid_controller = ValidTestController.new
  puts "Testing with valid friendly_id: #{valid_post.friendly_id}"
  
  begin
    valid_controller.set_post
    
    if valid_controller.redirected?
      puts "❌ Unexpected redirect with valid ID"
    else
      puts "✅ Valid ID handled correctly - no redirect"
      puts "   Post found: #{valid_controller.instance_variable_get(:@post)&.title}"
    end
    
  rescue => e
    puts "❌ Unexpected error with valid ID: #{e.class.name}: #{e.message}"
  end
else
  puts "No posts available for testing valid lookup"
end

puts
puts "=== Fix Summary ==="
puts "The fix adds proper exception handling to the set_post method"
puts "Invalid friendly_ids now redirect to posts index with error message"
puts "Valid friendly_ids continue to work as expected"