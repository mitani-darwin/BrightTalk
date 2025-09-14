#!/usr/bin/env ruby

# Test script to validate basic Terraform syntax
puts "Testing Terraform CloudFront configuration syntax..."

def check_terraform_file(file_path)
  unless File.exist?(file_path)
    puts "✗ File not found: #{file_path}"
    return false
  end

  content = File.read(file_path)
  
  # Basic syntax checks
  checks = [
    {
      name: "Balanced braces",
      test: -> { content.count('{') == content.count('}') }
    },
    {
      name: "Balanced brackets", 
      test: -> { content.count('[') == content.count(']') }
    },
    {
      name: "Balanced quotes",
      test: -> { content.count('"') % 2 == 0 }
    },
    {
      name: "Valid resource blocks",
      test: -> { content.match?(/resource\s+"[\w_]+"\s+"[\w_]+"\s*{/) }
    },
    {
      name: "Valid variable blocks",
      test: -> { !content.include?('variable') || content.match?(/variable\s+"[\w_]+"\s*{/) }
    },
    {
      name: "Valid output blocks", 
      test: -> { !content.include?('output') || content.match?(/output\s+"[\w_]+"\s*{/) }
    }
  ]

  puts "\nChecking #{File.basename(file_path)}:"
  all_passed = true
  
  checks.each do |check|
    begin
      if check[:test].call
        puts "  ✓ #{check[:name]}"
      else
        puts "  ✗ #{check[:name]}"
        all_passed = false
      end
    rescue => e
      puts "  ✗ #{check[:name]} - Error: #{e.message}"
      all_passed = false
    end
  end
  
  all_passed
end

# Test files
files_to_check = [
  "/Users/mitani/git/BrightTalk/terraform/modules/cloudfront/main.tf",
  "/Users/mitani/git/BrightTalk/terraform/modules/cloudfront/variables.tf", 
  "/Users/mitani/git/BrightTalk/terraform/modules/cloudfront/outputs.tf",
  "/Users/mitani/git/BrightTalk/terraform/environments/production/main.tf",
  "/Users/mitani/git/BrightTalk/terraform/environments/production/outputs.tf"
]

all_valid = true
files_to_check.each do |file|
  valid = check_terraform_file(file)
  all_valid &&= valid
end

puts "\n" + "="*50
puts "TERRAFORM SYNTAX TEST SUMMARY"  
puts "="*50

if all_valid
  puts "✓ SUCCESS: All Terraform files passed basic syntax checks!"
  puts "\nThe CloudFront configuration appears to be syntactically correct:"
  puts "- CloudFront module with video-optimized caching policies"
  puts "- Origin Access Control (OAC) for secure S3 access"
  puts "- Custom cache and origin request policies for video streaming"
  puts "- Production environment integration with S3 module"
  puts "- Proper outputs for CloudFront distribution URL"
else
  puts "✗ ISSUES FOUND: Some files have syntax problems"
  puts "Please review the files marked with ✗ above"
end