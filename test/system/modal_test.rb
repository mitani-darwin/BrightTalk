require "application_system_test_case"

class ModalTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:test_user)
    sign_in @user
  end

  test "modal displays when clicking submit button on new post form" do
    # Visit the new post page
    visit '/posts/new'
    
    # Fill in required fields
    fill_in 'post[title]', with: 'Test Modal Post'
    fill_in 'post[content]', with: 'This is a test post to check modal functionality'
    
    # Check if modal exists in DOM but is hidden
    assert_selector '#updateProgressModal', visible: :hidden
    
    # Check if submit button exists
    assert_selector '#updateSubmitBtn'
    
    # Execute JavaScript to check Bootstrap availability before clicking
    bootstrap_available = page.evaluate_script('typeof bootstrap !== "undefined"')
    assert bootstrap_available, "Bootstrap should be available"
    
    # Click the submit button
    find('#updateSubmitBtn').click
    
    # Wait a moment for modal to appear
    sleep(1)
    
    # Check if modal is visible
    assert_selector '#updateProgressModal', visible: :visible
    
    # Check for JavaScript console errors
    console_logs = page.driver.browser.logs.get(:browser)
    error_logs = console_logs.select { |log| log.level == "SEVERE" }
    assert error_logs.empty?, "No console errors should occur: #{error_logs.map(&:message).join(', ')}"
  end

  test "modal functionality works without errors when bootstrap is available" do
    visit '/posts/new'
    
    # Fill in form
    fill_in 'post[title]', with: 'Test Modal Post'
    fill_in 'post[content]', with: 'This is a test post to check modal functionality'
    
    # Verify Bootstrap is loaded
    bootstrap_loaded = page.evaluate_script('typeof bootstrap !== "undefined"')
    assert bootstrap_loaded, "Bootstrap should be loaded for modal functionality"
    
    # Check that modal-related JavaScript functions exist if they're defined globally
    has_modal_functions = page.evaluate_script('typeof initializeUpdateProgressModal === "function" || typeof handleUpdateSubmit === "function"')
    
    # Click submit and verify no JavaScript errors occur
    find('#updateSubmitBtn').click
    sleep(0.5)
    
    # Verify no severe JavaScript errors
    console_logs = page.driver.browser.logs.get(:browser)
    severe_errors = console_logs.select { |log| log.level == "SEVERE" }
    assert severe_errors.empty?, "Should not have JavaScript errors: #{severe_errors.map(&:message).join(', ')}"
  end

end
