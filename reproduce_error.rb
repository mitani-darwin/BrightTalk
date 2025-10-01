#!/usr/bin/env ruby

# Script to reproduce the publish button error from drafts
# This simulates the PATCH request that causes the NoMethodError

puts "=== Reproducing Publish Button Error ==="
puts "This script simulates the issue described in the logs:"
puts "- PATCH request to /posts/ID with only id parameter"
puts "- No post parameter present"
puts "- process_video_uploads tries to access params[:post][:videos]"
puts "- Fails with NoMethodError: undefined method '[]' for nil"
puts

# Simulate the parameters that would be sent by the publish button
params = {
  controller: "posts",
  action: "update",
  id: "824-50f-69f",
  commit: "公開"
}

puts "Simulated params: #{params.inspect}"
puts "params[:post] = #{params[:post].inspect}"
puts

# This is what happens in process_video_uploads line 521:
begin
  # Line 521: videos_present = params[:post][:videos].present?
  puts "Attempting: params[:post][:videos].present?"
  videos_present = params[:post][:videos].present?
  puts "Success: #{videos_present}"
rescue NoMethodError => e
  puts "ERROR: #{e.message}"
  puts "This confirms the issue - params[:post] is nil"
end

puts
puts "=== Root Cause Identified ==="
puts "The publish button in drafts.html.erb (lines 59-65) sends a PATCH request"
puts "with only commit parameter, but update action always calls process_video_uploads"
puts "which expects params[:post] to exist for video processing."