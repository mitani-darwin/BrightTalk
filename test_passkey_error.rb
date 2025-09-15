#!/usr/bin/env ruby
# Script to reproduce the passkey domain validation error

require_relative 'config/environment'

puts "Current Rails environment: #{Rails.env}"
puts "WebAuthn configuration:"
puts "  Allowed origins: #{WebAuthn.configuration.allowed_origins}"
puts "  RP ID: #{WebAuthn.configuration.rp_id}"
puts "  RP Name: #{WebAuthn.configuration.rp_name}"

puts "\nPasskeys controller configuration (hardcoded):"
if Rails.env.development?
  puts "  RP ID: localhost"
  puts "  Expected domain: localhost"
else
  puts "  RP ID: www.brighttalk.jp"
  puts "  Expected domain: www.brighttalk.jp"
end

puts "\nThe error occurs because:"
puts "1. WebAuthn API validates that the RP ID matches the effective domain"
puts "2. If running on a different port (e.g., localhost:3001) or subdomain,"
puts "   the hardcoded 'localhost' RP ID will cause a SecurityError"
puts "3. The solution is to use WebAuthn.configuration values or make it more flexible"

# Simulate the error scenario
puts "\nTo reproduce the error:"
puts "1. Run the app on a port other than 3000 (e.g., rails s -p 3001)"
puts "2. Try to register a passkey"
puts "3. The browser will throw: 'SecurityError: The effective domain of the document is not a valid domain.'"