#!/usr/bin/env ruby

# Test script to verify the duplicate request fix
# This checks if the frontend no longer makes duplicate verify_passkey requests

require_relative 'config/environment'

puts "Testing duplicate request fix..."
puts "=" * 50

# Test 1: Check the frontend view for duplicate requests
puts "\n1. Checking frontend view for duplicate verify_passkey requests..."

view_content = File.read('/Users/mitani/git/BrightTalk/app/views/passkey_registrations/new.html.erb')

# Count occurrences of verify_passkey fetch calls
verify_passkey_fetch_count = view_content.scan(/fetch.*verify_passkey/).length

puts "Found #{verify_passkey_fetch_count} verify_passkey fetch calls in frontend view"

if verify_passkey_fetch_count == 0
  puts "✓ No duplicate verify_passkey fetch calls found in frontend"
else
  puts "✗ Still has #{verify_passkey_fetch_count} verify_passkey fetch calls in frontend"
end

# Test 2: Check if startPasskeyRegistration result is properly handled
if view_content.include?('startPasskeyRegistration') && view_content.include?('result.show_confirmation_notice')
  puts "✓ Frontend properly handles startPasskeyRegistration result"
else
  puts "✗ Frontend may not properly handle startPasskeyRegistration result"
end

# Test 3: Check if the original JavaScript function still makes the verify_passkey call
puts "\n2. Checking JavaScript function for verify_passkey call..."

js_content = File.read('/Users/mitani/git/BrightTalk/app/javascript/passkey.js')

if js_content.include?("fetch('/passkey_registrations/verify_passkey'")
  puts "✓ JavaScript function still contains verify_passkey call (this is correct)"
else
  puts "✗ JavaScript function missing verify_passkey call (this would be a problem)"
end

# Test 4: Simulate the expected flow
puts "\n3. Expected flow after fix:"
puts "  1. Frontend calls startPasskeyRegistration()"
puts "  2. startPasskeyRegistration() internally calls verify_passkey"
puts "  3. Frontend receives result directly from startPasskeyRegistration()"
puts "  4. No duplicate requests, no session clearing before verification"

puts "\n" + "=" * 50
puts "Test completed!"
puts "\nThe fix should eliminate the 404 'Filter chain halted as :find_pending_user' error"
puts "because there's now only one verify_passkey request instead of two."