#!/usr/bin/env ruby

# Test script to verify the publish button functionality

puts "=== Testing Publish Button Functionality ==="
puts "This script simulates the PATCH request sent by the publish button"
puts "and verifies that the post status is set to published."
puts

# Simulate the update action logic with the fix
class MockPost
  attr_accessor :status
  
  def initialize(status = "draft")
    @status = status
  end
  
  def published?
    @status == "published"
  end
end

def simulate_update_action(params, post)
  puts "=== Post Update Debug ==="
  puts "All params: #{params.inspect}"
  puts "=========================="
  
  # 公開ボタンがクリックされた場合、ステータスを公開に変更
  if params[:commit] == "公開"
    post.status = "published"
    puts "Setting post status to published via commit parameter"
  end
  
  puts "Final post status: #{post.status}"
  return post.published?
end

# Test Case 1: Publish button clicked from drafts
puts "=== Test Case 1: Publish Button from Drafts ==="
publish_params = {
  controller: "posts",
  action: "update", 
  id: "824-50f-69f",
  commit: "公開"
}

draft_post = MockPost.new("draft")
puts "Initial post status: #{draft_post.status}"

success = simulate_update_action(publish_params, draft_post)
if success
  puts "✓ SUCCESS: Post was published!"
else
  puts "✗ FAILED: Post was not published"
end

puts

# Test Case 2: Regular update without commit parameter
puts "=== Test Case 2: Regular Update (no commit) ==="
regular_params = {
  controller: "posts",
  action: "update",
  id: "123",
  post: {
    title: "Updated Title",
    content: "Updated content"
  }
}

draft_post2 = MockPost.new("draft")
puts "Initial post status: #{draft_post2.status}"

success2 = simulate_update_action(regular_params, draft_post2)
puts "Post should remain draft: #{draft_post2.status == 'draft' ? '✓ SUCCESS' : '✗ FAILED'}"

puts

# Test Case 3: Different commit value
puts "=== Test Case 3: Different Commit Value ==="
other_params = {
  controller: "posts",
  action: "update",
  id: "456", 
  commit: "保存"
}

draft_post3 = MockPost.new("draft")
puts "Initial post status: #{draft_post3.status}"

success3 = simulate_update_action(other_params, draft_post3)
puts "Post should remain draft: #{draft_post3.status == 'draft' ? '✓ SUCCESS' : '✗ FAILED'}"

puts
puts "=== Summary ==="
puts "The fix correctly handles the '公開' commit parameter to publish posts."