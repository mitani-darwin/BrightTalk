#!/usr/bin/env ruby

# Test script to reproduce modal display issue
# This script will check if the modal appears when clicking the submit button

require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'

Capybara.configure do |config|
  config.app_host = 'http://localhost:3000'
  config.default_driver = :selenium_chrome_headless
  config.default_max_wait_time = 10
end

class ModalTest
  include Capybara::DSL

  def test_modal_display
    puts "Starting modal display test..."
    
    # Visit the new post page
    visit '/posts/new'
    puts "Visited /posts/new"
    
    # Fill in required fields
    fill_in 'post[title]', with: 'Test Modal Post'
    fill_in 'post[content]', with: 'This is a test post to check modal functionality'
    puts "Filled in required fields"
    
    # Check if modal exists in DOM
    modal_exists = page.has_css?('#updateProgressModal', visible: :hidden)
    puts "Modal exists in DOM: #{modal_exists}"
    
    # Check if submit button exists
    submit_btn_exists = page.has_css?('#updateSubmitBtn')
    puts "Submit button exists: #{submit_btn_exists}"
    
    # Click submit button
    if submit_btn_exists
      puts "Clicking submit button..."
      
      # Click the submit button
      find('#updateSubmitBtn').click
      
      # Wait a moment for modal to appear
      sleep(1)
      
      # Check if modal is visible
      modal_visible = page.has_css?('#updateProgressModal', visible: :visible)
      puts "Modal visible after click: #{modal_visible}"
      
      # Check JavaScript console for errors
      console_logs = page.driver.browser.logs.get(:browser)
      if console_logs.any?
        puts "Console messages:"
        console_logs.each { |log| puts "  #{log.level}: #{log.message}" }
      end
      
      return modal_visible
    else
      puts "Submit button not found!"
      return false
    end
    
  rescue => e
    puts "Error during test: #{e.message}"
    puts e.backtrace
    return false
  end
end

if __FILE__ == $0
  test = ModalTest.new
  result = test.test_modal_display
  puts "\nTest result: #{result ? 'PASS' : 'FAIL'}"
  exit(result ? 0 : 1)
end
