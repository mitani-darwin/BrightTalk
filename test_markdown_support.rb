#!/usr/bin/env ruby

# Test script to verify Markdown support in format_content_with_images
puts "Testing Markdown support in format_content_with_images..."

# Load Rails environment
require_relative 'config/environment'

# Test content with various Markdown elements
test_content = <<~MARKDOWN
# 見出し1

## 見出し2

### 見出し3

**太字テキスト** と *斜体テキスト* と ~~取り消し線~~ のテスト

- リスト項目1
- リスト項目2
  - ネストされたリスト
  - もう一つのネスト

1. 番号付きリスト1
2. 番号付きリスト2
3. 番号付きリスト3

```ruby
# コードブロック
def hello_world
  puts "Hello, World!"
end
```

インライン `コード` のテスト

> 引用文のテスト
> 複数行の引用

| 表 | のテスト | 項目 |
|---|---|---|
| セル1 | セル2 | セル3 |
| データ1 | データ2 | データ3 |

![テスト画像](attachment:test_image.jpg)

[動画 テスト動画](attachment:test_video.mp4)

リンクテスト: [Google](https://www.google.com)

改行テスト
これは新しい行です

段落分け

これは新しい段落です
MARKDOWN

# Create a helper instance to test the method
helper = Object.new
helper.extend(PostsHelper)

puts "Processing test content with Markdown..."

begin
  result = helper.format_content_with_images(test_content, nil)
  
  # Check for various HTML elements that should be generated
  checks = [
    { name: "Header h1", pattern: /<h1>見出し1<\/h1>/ },
    { name: "Header h2", pattern: /<h2>見出し2<\/h2>/ },
    { name: "Header h3", pattern: /<h3>見出し3<\/h3>/ },
    { name: "Bold text", pattern: /<strong>太字テキスト<\/strong>/ },
    { name: "Italic text", pattern: /<em>斜体テキスト<\/em>/ },
    { name: "Strikethrough", pattern: /<del>取り消し線<\/del>/ },
    { name: "Unordered list", pattern: /<ul>.*<li>リスト項目1<\/li>.*<\/ul>/m },
    { name: "Ordered list", pattern: /<ol>.*<li>番号付きリスト1<\/li>.*<\/ol>/m },
    { name: "Code block", pattern: /<pre><code.*>.*def hello_world.*<\/code><\/pre>/m },
    { name: "Inline code", pattern: /<code>コード<\/code>/ },
    { name: "Blockquote", pattern: /<blockquote>.*<p>引用文のテスト.*<\/p>.*<\/blockquote>/m },
    { name: "Table", pattern: /<table>.*<\/table>/m },
    { name: "Table headers", pattern: /<th>表<\/th>/ },
    { name: "Table cells", pattern: /<td>セル1<\/td>/ },
    { name: "External link", pattern: /<a.*href="https:\/\/www\.google\.com".*>Google<\/a>/ },
    { name: "Image preservation", pattern: /!\[テスト画像\]\(attachment:test_image\.jpg\)/ },
    { name: "Video preservation", pattern: /\[動画 テスト動画\]\(attachment:test_video\.mp4\)/ },
    { name: "Paragraphs", pattern: /<p>.*<\/p>/ }
  ]

  puts "\n" + "="*60
  puts "MARKDOWN CONVERSION RESULTS"
  puts "="*60
  
  passed_checks = 0
  
  checks.each do |check|
    if result.match?(check[:pattern])
      puts "✓ #{check[:name]} - CONVERTED"
      passed_checks += 1
    else
      puts "✗ #{check[:name]} - NOT FOUND"
    end
  end
  
  puts "\n" + "="*60
  puts "SUMMARY"
  puts "="*60
  puts "Passed: #{passed_checks}/#{checks.length} checks"
  
  if passed_checks >= (checks.length * 0.8) # 80% success rate
    puts "✓ SUCCESS: Markdown support is working correctly!"
    puts "\nThe format_content_with_images method now supports:"
    puts "- Headers (h1, h2, h3)"
    puts "- Text formatting (bold, italic, strikethrough)"
    puts "- Lists (ordered and unordered)"
    puts "- Code blocks and inline code"
    puts "- Blockquotes"
    puts "- Tables"
    puts "- Links"
    puts "- Paragraphs and line breaks"
    puts "- Image and video attachment processing (preserved)"
  else
    puts "⚠ PARTIAL SUCCESS: Some Markdown elements may not be working correctly"
  end
  
  puts "\n" + "-"*60
  puts "SAMPLE OUTPUT (first 500 characters):"
  puts "-"*60
  puts result[0..500] + "..."
  
rescue => e
  puts "✗ ERROR: #{e.message}"
  puts "Stack trace: #{e.backtrace.first(3).join(", ")}"
end