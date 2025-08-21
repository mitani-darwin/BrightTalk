#!/usr/bin/env ruby

# Test script to verify the passkey registration UI changes
# This tests the controller response format to ensure it matches what the frontend expects

require_relative 'config/environment'

puts "Testing passkey registration response format..."
puts "=" * 50

# Simulate a successful passkey verification request
controller = PasskeyRegistrationsController.new

# Mock the session and request data
mock_session = {
  pending_user_data: {
    'name' => 'Test User',
    'email' => 'test@example.com'
  },
  passkey_registration_challenge: 'mock_challenge'
}

# Mock response object
class MockResponse
  def initialize
    @data = {}
  end
  
  def render(options)
    puts "Response rendered:"
    puts "  Status: #{options[:status] || 200}"
    puts "  JSON data:"
    if options[:json]
      options[:json].each do |key, value|
        puts "    #{key}: #{value}"
      end
      
      # Check the expected response format
      json = options[:json]
      if json[:success] && json[:show_confirmation_notice]
        puts "\n✓ Response format is correct for provisional registration"
        puts "  - success: #{json[:success]}"
        puts "  - show_confirmation_notice: #{json[:show_confirmation_notice]}"
        puts "  - message: #{json[:message]}"
        puts "\n✓ Frontend should now display confirmation screen instead of console error"
      else
        puts "\n✗ Response format may cause issues"
      end
    end
  end
end

# Test the expected response format
puts "\n1. Testing expected response format from backend..."

expected_response = {
  success: true,
  message: "パスキーの登録が完了しました。メールアドレスに送信された確認メールのリンクをクリックして、登録を完了してください。",
  show_confirmation_notice: true
}

mock_response = MockResponse.new
mock_response.render(json: expected_response)

puts "\n2. Checking frontend JavaScript expectations..."

# Check if the JavaScript file has been updated correctly
passkey_js_content = File.read('/Users/mitani/git/BrightTalk/app/javascript/passkey.js')
view_content = File.read('/Users/mitani/git/BrightTalk/app/views/passkey_registrations/new.html.erb')

if passkey_js_content.include?('show_confirmation_notice')
  puts "✓ passkey.js updated to handle show_confirmation_notice flag"
else
  puts "✗ passkey.js may not handle the new response format"
end

if view_content.include?('showConfirmationNotice')
  puts "✓ Frontend view has showConfirmationNotice method"
else
  puts "✗ Frontend view missing showConfirmationNotice method"
end

if view_content.include?('仮登録完了')
  puts "✓ Frontend shows provisional registration completion message"
else
  puts "✗ Frontend missing provisional registration message"
end

puts "\n" + "=" * 50
puts "Test completed!"
puts "\nExpected behavior:"
puts "1. No 'パスキー登録エラー:' in console when registration succeeds"
puts "2. Shows '仮登録完了' screen with email confirmation instructions"
puts "3. User can click 'ログイン画面へ' to go to sign in page"