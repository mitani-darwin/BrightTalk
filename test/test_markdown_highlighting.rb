#!/usr/bin/env ruby

puts "Testing Markdown Highlighting Implementation"
puts "=" * 50

# Check if we're in a Rails project
if File.exist?('config/application.rb')
  puts "✓ Rails project detected"
else
  puts "✗ Not in Rails project root"
  exit 1
end

# Check for CodeMirror controller
controller_path = 'app/javascript/controllers/code_editor_controller.js'
if File.exist?(controller_path)
  puts "✓ CodeEditor controller found"
  
  # Read and analyze the controller
  content = File.read(controller_path)
  
  if content.include?('markdown()')
    puts "✓ Markdown extension is configured"
  else
    puts "✗ Markdown extension not found"
  end
  
  if content.include?('CodeMirror 6')
    puts "✓ Using CodeMirror 6"
  else
    puts "? CodeMirror version unclear"
  end
  
else
  puts "✗ CodeEditor controller not found"
end

# Check form implementation
form_path = 'app/views/posts/_form_main_content.html.erb'
if File.exist?(form_path)
  puts "✓ Form template found"
  
  content = File.read(form_path)
  if content.include?('data-controller="code-editor"')
    puts "✓ CodeEditor controller is attached to form"
  else
    puts "✗ CodeEditor controller not attached"
  end
else
  puts "✗ Form template not found"
end

# Check for JavaScript dependencies
package_json_path = 'package.json'
if File.exist?(package_json_path)
  puts "✓ package.json found"
  
  content = File.read(package_json_path)
  if content.include?('codemirror')
    puts "✓ CodeMirror dependency found in package.json"
  else
    puts "✗ CodeMirror dependency not found in package.json"
  end
else
  puts "✗ package.json not found"
end

puts "\nRecommendations for CodeMirror5-like markdown highlighting:"
puts "1. Ensure CodeMirror 6 markdown extension provides visible syntax highlighting"
puts "2. Check if additional themes or styling is needed for better visibility"
puts "3. Verify that the highlighting covers all markdown syntax (headers, bold, italic, code, etc.)"
puts "4. Test in browser to see actual highlighting behavior"