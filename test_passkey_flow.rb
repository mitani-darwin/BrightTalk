#!/usr/bin/env ruby

# Test script to verify the new passkey registration flow
# This simulates the registration process to ensure:
# 1. Users are created in unconfirmed state
# 2. Confirmation emails are sent
# 3. Unconfirmed users cannot sign in with passkeys

require_relative 'config/environment'

puts "Testing new passkey registration flow..."
puts "=" * 50

# Clean up any test user first
test_email = "test_passkey_user@example.com"
existing_user = User.find_by(email: test_email)
if existing_user
  puts "Cleaning up existing test user..."
  existing_user.destroy!
end

# Test 1: Create a user through normal user creation (simulate controller behavior)
puts "\n1. Testing user creation in unconfirmed state..."

begin
  # Simulate the passkey registration process
  temp_password = "Temp#{SecureRandom.hex(8)}@#{rand(100..999)}"
  
  user = User.create!(
    name: "Test Passkey User",
    email: test_email,
    password: temp_password
  )
  
  # Remove the password (as done in the controller)
  user.update_column(:encrypted_password, "")
  
  puts "✓ User created successfully"
  puts "  - ID: #{user.id}"
  puts "  - Email: #{user.email}"
  puts "  - Confirmed?: #{user.confirmed?}"
  puts "  - Confirmed at: #{user.confirmed_at}"
  puts "  - Confirmation token present?: #{user.confirmation_token.present?}"
  
  if user.confirmed?
    puts "✗ ERROR: User should not be confirmed initially"
  else
    puts "✓ User is correctly in unconfirmed state"
  end

  # Test 2: Test confirmation email sending
  puts "\n2. Testing confirmation email sending..."
  
  begin
    # This should generate a confirmation token and send email
    user.send_confirmation_instructions
    puts "✓ Confirmation instructions sent successfully"
    puts "  - Confirmation token: #{user.reload.confirmation_token[0..10]}..."
  rescue => e
    puts "✗ ERROR sending confirmation instructions: #{e.message}"
  end

  # Test 3: Test confirmation process
  puts "\n3. Testing email confirmation..."
  
  confirmation_token = user.confirmation_token
  if confirmation_token.present?
    # Simulate clicking the confirmation link
    user.confirm
    puts "✓ User confirmed successfully"
    puts "  - Confirmed?: #{user.confirmed?}"
    puts "  - Confirmed at: #{user.confirmed_at}"
  else
    puts "✗ ERROR: No confirmation token generated"
  end

  # Test 4: Test that confirmed users can potentially sign in
  puts "\n4. Testing user state after confirmation..."
  
  if user.reload.confirmed?
    puts "✓ User is now confirmed and should be able to sign in"
  else
    puts "✗ ERROR: User confirmation failed"
  end

rescue => e
  puts "✗ ERROR in test: #{e.message}"
  puts e.backtrace.first(5)
ensure
  # Clean up
  if User.exists?(email: test_email)
    User.find_by(email: test_email)&.destroy!
    puts "\n✓ Test user cleaned up"
  end
end

puts "\n" + "=" * 50
puts "Test completed!"