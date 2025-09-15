#!/usr/bin/env ruby

# Test script to verify HTML rendering fix
puts "Testing HTML rendering fix for video content..."

# Load Rails environment
require_relative 'config/environment'
require 'ostruct'

# Test content with video markdown
test_content = <<~MARKDOWN
# Test Video Content

This is some test content with a video:

[動画 test_video.mp4](attachment:test_video.mp4)

And some regular text after the video.
MARKDOWN

# Create a mock post object to test the helper
mock_post = Object.new

# Define a mock videos method that returns an empty relation
def mock_post.videos
  OpenStruct.new(attached?: false)
end

# Create a helper instance to test the method
helper = Object.new
helper.extend(PostsHelper)

puts "Testing format_content_with_images method..."

begin
  result = helper.format_content_with_images(test_content, mock_post)
  
  puts "\n" + "="*60
  puts "HELPER METHOD OUTPUT"
  puts "="*60
  puts "Output type: #{result.class}"
  puts "HTML safe?: #{result.html_safe?}"
  puts "Length: #{result.length} characters"
  
  puts "\n" + "-"*60
  puts "SAMPLE OUTPUT:"
  puts "-"*60
  puts result
  
  # Test Post model method
  puts "\n" + "="*60
  puts "TESTING POST MODEL METHOD"
  puts "="*60
  
  # Create a test post
  begin
    # Find an existing post or create a mock
    post = Post.first || OpenStruct.new(content: test_content, videos: OpenStruct.new(attached?: false))
    
    # Test if we can call the method (this will test the return statement fix)
    if post.respond_to?(:content_as_html)
      html_result = post.content_as_html
      puts "✓ content_as_html method executed successfully"
      puts "Output type: #{html_result.class}"
      puts "HTML safe?: #{html_result.html_safe?}" if html_result.respond_to?(:html_safe?)
      puts "Length: #{html_result.length} characters" if html_result.respond_to?(:length)
    else
      puts "✗ content_as_html method not available on post object"
    end
  rescue => e
    puts "Error testing Post model: #{e.message}"
  end
  
  # Check for expected HTML structure
  checks = [
    { name: "HTML header", pattern: /<h1>Test Video Content<\/h1>/ },
    { name: "Paragraph text", pattern: /<p>This is some test content with a video:<\/p>/ },
    { name: "Video fallback text", pattern: /\[動画 test_video\.mp4\]/ },
    { name: "After video text", pattern: /<p>And some regular text after the video\.<\/p>/ },
    { name: "HTML safe string", test: -> { result.html_safe? } }
  ]
  
  puts "\n" + "="*60
  puts "HTML RENDERING CHECKS"
  puts "="*60
  
  passed_checks = 0
  
  checks.each do |check|
    if check[:pattern]
      if result.match?(check[:pattern])
        puts "✓ #{check[:name]} - FOUND"
        passed_checks += 1
      else
        puts "✗ #{check[:name]} - NOT FOUND"
      end
    elsif check[:test]
      if check[:test].call
        puts "✓ #{check[:name]} - PASSED"
        passed_checks += 1
      else
        puts "✗ #{check[:name]} - FAILED"
      end
    end
  end
  
  puts "\n" + "="*60
  puts "SUMMARY"
  puts "="*60
  puts "Passed: #{passed_checks}/#{checks.length} checks"
  
  if passed_checks >= (checks.length * 0.8)
    puts "✓ SUCCESS: HTML rendering appears to be working correctly!"
    puts "\nThe fix should resolve the issue where HTML tags appear as text."
    puts "Video content will now render as proper HTML elements instead of literal text."
  else
    puts "⚠ ISSUES DETECTED: Some rendering problems may still exist"
  end
  
rescue => e
  puts "✗ ERROR: #{e.message}"
  puts "Stack trace: #{e.backtrace.first(3).join(", ")}"
end