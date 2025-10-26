#!/usr/bin/env ruby

# Test script to verify the fix for the publish button error

puts "=== Testing the Fix ==="
puts "Simulating the process_video_uploads method with the fix..."
puts

# Simulate the fixed method logic
def process_video_uploads(params)
  puts "=== Video Upload Processing Started ==="
  
  # params[:post]の存在チェックを追加 (THE FIX)
  return unless params[:post].present?
  
  # 両方のパラメータをチェック
  videos_present = params[:post][:videos].present?
  signed_ids_present = params[:post][:video_signed_ids].present?
  
  puts "Videos parameter present: #{videos_present}"
  puts "Video signed_ids parameter present: #{signed_ids_present}"
  
  return unless videos_present || signed_ids_present
  
  puts "Would process videos here..."
  puts "=== Video Upload Processing Completed ==="
end

# Test Case 1: Publish button scenario (params[:post] is nil)
puts "=== Test Case 1: Publish Button Scenario ==="
publish_params = {
  controller: "posts",
  action: "update", 
  id: "824-50f-69f",
  commit: "公開"
}

puts "Params: #{publish_params.inspect}"
puts "params[:post] = #{publish_params[:post].inspect}"

begin
  process_video_uploads(publish_params)
  puts "✓ SUCCESS: No error occurred!"
rescue => e
  puts "✗ FAILED: #{e.message}"
end

puts
puts "=== Test Case 2: Normal Form Submission with Video ==="
form_params = {
  controller: "posts",
  action: "update",
  id: "123",
  post: {
    title: "Test Post",
    content: "Test content",
    videos: ["video1.mp4"]
  }
}

puts "Params: #{form_params.inspect}"
begin
  process_video_uploads(form_params)
  puts "✓ SUCCESS: Video processing would run normally"
rescue => e
  puts "✗ FAILED: #{e.message}"
end

puts
puts "=== Test Case 3: Form Submission without Videos ==="
no_video_params = {
  controller: "posts", 
  action: "update",
  id: "456",
  post: {
    title: "Test Post",
    content: "Test content"
  }
}

puts "Params: #{no_video_params.inspect}"
begin
  process_video_uploads(no_video_params)
  puts "✓ SUCCESS: No video processing needed, exited gracefully"
rescue => e
  puts "✗ FAILED: #{e.message}"
end