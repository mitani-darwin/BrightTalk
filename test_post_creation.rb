#!/usr/bin/env ruby
# Test script to reproduce the post creation issue

require 'test_helper'

class PostCreationTest < ApplicationSystemTestCase
  def setup
    @user = users(:test_user)
    @category = categories(:general)
    @post_type = post_types(:tutorial) if PostType.exists?(name: 'tutorial')
    @post_type ||= PostType.first
  end

  def test_reproduce_post_creation_issue
    # Sign in user
    sign_in @user
    
    # Visit new post page
    visit new_post_path
    
    puts "Current URL: #{current_url}"
    puts "Page title: #{page.title}"
    
    # Check if form exists
    assert page.has_css?('form'), "Form not found on page"
    puts "Form found: ✓"
    
    # Fill required fields
    fill_in 'post[title]', with: 'Test Reproduction Post'
    puts "Title filled: ✓"
    
    fill_in 'post[content]', with: 'Test content for reproduction'
    puts "Content filled: ✓"
    
    fill_in 'post[purpose]', with: 'Test purpose'
    puts "Purpose filled: ✓"
    
    fill_in 'post[target_audience]', with: 'Test audience'
    puts "Target audience filled: ✓"
    
    # Select post type and category
    if @post_type
      select @post_type.display_name, from: 'post[post_type_id]'
      puts "Post type selected: ✓"
    end
    
    if @category
      select @category.full_name, from: 'post[category_id]'
      puts "Category selected: ✓"
    end
    
    puts "About to click submit button..."
    
    # Click submit
    click_button '投稿'
    
    puts "After submit - Current URL: #{current_url}"
    puts "Page content snippet: #{page.body[0..500]}"
    
    # Check if post was created
    if page.has_content?('Test Reproduction Post')
      puts "SUCCESS: Post title found on page"
    else
      puts "FAILED: Post title not found on page"
      puts "Looking for success messages..."
      ['投稿が作成されました', 'Post was successfully created'].each do |msg|
        if page.has_content?(msg)
          puts "Found success message: #{msg}"
        end
      end
    end
    
    # Check if there are validation errors
    if page.has_css?('.alert-danger')
      puts "Validation errors found:"
      page.all('.alert-danger').each do |alert|
        puts "  - #{alert.text}"
      end
    end
  end
end