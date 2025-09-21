#!/usr/bin/env ruby

# Script to reproduce the ruby-vips PNG processing error
require 'tempfile'
require 'fileutils'

puts "Testing ruby-vips PNG processing..."

begin
  require "ruby-vips"
  puts "✓ ruby-vips loaded successfully"
rescue LoadError => e
  puts "✗ Failed to load ruby-vips: #{e.message}"
  exit 1
end

# Check if we have PNG format support
puts "\nChecking available formats in ruby-vips..."
begin
  formats = Vips.get_suffixes
  puts "Available formats: #{formats.join(', ')}"
  
  if formats.include?('.png')
    puts "✓ PNG format is supported"
  else
    puts "✗ PNG format is NOT supported"
  end
rescue => e
  puts "Error getting formats: #{e.message}"
end

# Create a simple test PNG file
puts "\nCreating test PNG file..."
test_png_path = "/tmp/test_image.png"

# Create a simple 100x100 PNG image using ruby-vips
begin
  # Create a simple image
  test_image = Vips::Image.black(100, 100)
  test_image = test_image.new_from_image([255, 255, 255])
  test_image.write_to_file(test_png_path)
  puts "✓ Test PNG created at #{test_png_path}"
rescue => e
  puts "✗ Failed to create test PNG: #{e.message}"
  exit 1
end

# Test reading the PNG file (similar to what's failing in the Post model)
puts "\nTesting PNG file reading (similar to Post model line 159)..."
begin
  Tempfile.create(["original_", ".png"], binmode: true) do |tempfile|
    # Copy our test file to the tempfile (simulating S3 download)
    FileUtils.cp(test_png_path, tempfile.path)
    tempfile.rewind
    
    puts "Tempfile path: #{tempfile.path}"
    puts "Tempfile size: #{File.size(tempfile.path)} bytes"
    
    # This is the line that's failing (line 159 in Post model)
    image = Vips::Image.new_from_file(tempfile.path, access: :sequential)
    puts "✓ Successfully loaded PNG with dimensions: #{image.width}x#{image.height}"
    
    # Test writing with EXIF removal (strip: true)
    output_path = "/tmp/processed_test.png"
    image.write_to_file(output_path, compression: 6, strip: true)
    puts "✓ Successfully processed PNG with EXIF removal"
    
  end
rescue => e
  puts "✗ Failed to process PNG: #{e.class.name}: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n  ")}"
end

# Clean up
FileUtils.rm_f(test_png_path)
FileUtils.rm_f("/tmp/processed_test.png")

puts "\nTest completed."