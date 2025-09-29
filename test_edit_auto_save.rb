#!/usr/bin/env ruby
# Test script to reproduce auto-save issue specifically for edit mode

puts "=== Testing Auto-Save for Edit Mode ==="

# Test 1: Check if the form properly sets post_id for existing posts
puts "\n1. Checking form post_id field for edit mode:"
form_file = "/Users/mitani/git/BrightTalk/app/views/posts/_form.html.erb"
if File.exist?(form_file)
  content = File.read(form_file)
  if content.include?('post.persisted? ? post.slug : ""')
    puts "✓ Form correctly sets post_id for persisted posts (edit mode)"
  else
    puts "✗ Form does not properly handle post_id for edit mode"
  end
else
  puts "✗ Form file not found"
end

# Test 2: Check JavaScript auto-save path detection
puts "\n2. Checking JavaScript path detection for edit mode:"
js_file = "/Users/mitani/git/BrightTalk/app/views/posts/_form_javascript.html.erb"
if File.exist?(js_file)
  js_content = File.read(js_file)
  if js_content.include?("currentPath.includes('/edit')")
    puts "✓ JavaScript detects edit paths correctly"
  else
    puts "✗ JavaScript may not detect edit paths"
  end
else
  puts "✗ JavaScript file not found"
end

# Test 3: Check controller before_action for auto_save
puts "\n3. Checking controller before_action setup:"
controller_file = "/Users/mitani/git/BrightTalk/app/controllers/posts_controller.rb"
if File.exist?(controller_file)
  controller_content = File.read(controller_file)
  if controller_content.include?("before_action :set_post_for_auto_save, only: [:auto_save]")
    puts "✓ Controller has proper before_action for auto_save"
  else
    puts "✗ Controller missing before_action for auto_save"
  end
else
  puts "✗ Controller file not found"
end

# Test 4: Check set_post_for_auto_save method logic
puts "\n4. Checking set_post_for_auto_save method:"
if File.exist?(controller_file)
  controller_content = File.read(controller_file)
  
  if controller_content.include?("if params[:post_id].present?")
    puts "✓ Method checks for post_id parameter first"
  else
    puts "✗ Method may not properly check post_id parameter"
  end
  
  if controller_content.include?("current_user.posts.friendly.find(params[:post_id])")
    puts "✓ Method uses friendly finder for post_id"
  else
    puts "✗ Method may not use friendly finder for post_id"
  end
else
  puts "✗ Controller file not found"
end

# Test 5: Check auto_save_params method
puts "\n5. Checking auto_save_params method:"
if File.exist?(controller_file)
  controller_content = File.read(controller_file)
  
  if controller_content.include?("if params[:post_id].present?") && controller_content.include?("allowed_params[:post_id] = params[:post_id]")
    puts "✓ auto_save_params method handles post_id parameter"
  else
    puts "✗ auto_save_params method may not properly handle post_id"
  end
else
  puts "✗ Controller file not found"
end

puts "\n=== Potential Issues Analysis ==="
puts "\nBased on the code analysis, the auto-save implementation should work for edit mode."
puts "However, there might be subtle issues:"

puts "\n1. Parameter Structure Issue:"
puts "   The JavaScript sends FormData directly, but the controller expects nested params[:post]"
puts "   This could cause the auto_save_params method to fail parsing"

puts "\n2. Slug vs ID Issue:"
puts "   The form uses post.slug for post_id, but there might be cases where slug is not set"

puts "\n3. Authentication/Authorization Issue:"
puts "   The set_post_for_auto_save method might fail if user doesn't own the post"

puts "\nRecommended Fix:"
puts "Check the JavaScript FormData structure and ensure it matches the expected server-side format"