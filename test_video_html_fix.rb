#!/usr/bin/env ruby
# Test script to verify video HTML generation fix

require_relative 'config/environment'
require 'erb'

# Mock post with video attachment
class MockPost
  def videos
    MockVideos.new
  end
end

class MockVideos
  def attached?
    true
  end
  
  def find
    MockVideo.new
  end
end

class MockVideo
  def filename
    OpenStruct.new(to_s: "test_video.mp4")
  end
  
  def content_type
    "video/mp4"
  end
  
  def blob
    OpenStruct.new(key: "test_key")
  end
end

# Test the helper
include PostsHelper

# Mock Rails methods
def Rails.application
  OpenStruct.new(
    routes: OpenStruct.new(
      url_helpers: OpenStruct.new(
        rails_blob_path: lambda { |attachment, options| "/test/video/path.mp4" }
      )
    ),
    credentials: OpenStruct.new(
      dig: lambda { |*args| nil }
    )
  )
end

# Test content with video markdown
test_content = "[動画 test_video.mp4](attachment:test_video.mp4)"
mock_post = MockPost.new

puts "Testing video HTML generation..."
puts "Input markdown: #{test_content}"
puts

result = format_content_with_images(test_content, mock_post)
puts "Generated HTML:"
puts result
puts

# Check for malformed HTML patterns
if result.include?('<br="">') || result.include?('<br>') && !result.include?('<br>または')
  puts "❌ FAILED: HTML contains malformed line breaks"
else
  puts "✅ SUCCESS: HTML is properly formatted without malformed line breaks"
end

# Check that essential elements are present
required_elements = [
  'data-controller="video-player"',
  'data-video-player-target="video"',
  'class="video-js',
  '<source src=',
  'Video.jsを有効にするには'
]

missing_elements = required_elements.reject { |element| result.include?(element) }
if missing_elements.any?
  puts "❌ FAILED: Missing required elements: #{missing_elements.join(', ')}"
else
  puts "✅ SUCCESS: All required video player elements are present"
end