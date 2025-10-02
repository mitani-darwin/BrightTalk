#!/usr/bin/env ruby

# Test script to reproduce the CSP nil source error
puts "Testing Content Security Policy error reproduction..."

# Simulate the environment during assets:precompile
ENV['SECRET_KEY_BASE_DUMMY'] = '1'
ENV.delete('CLOUDFRONT_DISTRIBUTION_URL') # Ensure this is not set

# Load Rails environment
require_relative 'config/environment'

puts "Rails environment loaded successfully"
puts "Environment: #{Rails.env}"

# Try to trigger the CSP configuration
begin
  # This should trigger the CSP policy evaluation
  Rails.application.config.content_security_policy
  puts "CSP configuration completed successfully"
rescue => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(10)
end