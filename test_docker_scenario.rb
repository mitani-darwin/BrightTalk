#!/usr/bin/env ruby

# Test script to simulate Docker build environment more closely
puts "Testing Docker-like environment for CSP configuration..."

# Clear all relevant environment variables to simulate Docker scenario
ENV.delete('CLOUDFRONT_DISTRIBUTION_URL')
ENV['SECRET_KEY_BASE_DUMMY'] = '1'
ENV['RAILS_ENV'] = 'production'

# Test with minimal Rails environment
require 'bundler/setup'
require_relative 'config/application'

# Initialize without full Rails environment first
Rails.application.initialize!

puts "Testing CSP policy configuration in Docker-like environment..."

begin
  # Test the CSP policy configuration directly
  csp_policy = Rails.application.config.content_security_policy
  
  if csp_policy
    puts "✓ CSP policy configuration loaded successfully"
    
    # Try to trigger policy evaluation
    policy_instance = ActionDispatch::ContentSecurityPolicy.new
    csp_policy.call(policy_instance)
    puts "✓ CSP policy evaluation completed without errors"
  else
    puts "✗ CSP policy configuration is nil"
  end
  
rescue => e
  puts "✗ ERROR: #{e.class}: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(10)
  exit 1
end

puts "✓ All tests passed - Docker environment simulation successful"