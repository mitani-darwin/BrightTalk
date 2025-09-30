require "application_system_test_case"

class ImageSelectionFixTest < ApplicationSystemTestCase
  test "複数の画像を一つずつ選択して累積できることを確認" do
    # テスト用のHTMLページにアクセス
    visit_test_page

    # 必要な要素が存在することを確認
    assert_selector "#imageInput"
    assert_selector "#selectedFilesDisplay"

    # JavaScript関数が正しく定義されていることを確認
    assert page.evaluate_script("typeof handleImageUpload === 'function'")
    assert page.evaluate_script("typeof selectedFiles !== 'undefined'")

    # 初期状態では選択されたファイルが0個であることを確認
    initial_count = page.evaluate_script("selectedFiles.length")
    assert_equal 0, initial_count, "初期状態でselectedFilesが空でない"

    # 最初の画像を選択
    page.execute_script(<<~JS
      const imageInput = document.getElementById('imageInput');
      const mockFile1 = new File(['mock1'], 'test_image1.jpg', { type: 'image/jpeg' });
      const mockFileList1 = Object.create(FileList.prototype);
      mockFileList1[0] = mockFile1;
      Object.defineProperty(mockFileList1, 'length', { value: 1 });
      
      Object.defineProperty(imageInput, 'files', {
        value: mockFileList1,
        writable: false
      });
      
      const changeEvent = new Event('change', { bubbles: true });
      imageInput.dispatchEvent(changeEvent);
    JS
    )

    # 少し待機してイベント処理が完了するのを待つ
    sleep 1

    # 1つのファイルが選択されていることを確認
    first_selection_count = page.evaluate_script("selectedFiles.length")
    assert_equal 1, first_selection_count, "最初の選択後、selectedFilesに1個のファイルがない"

    # 2つ目の画像を選択
    page.execute_script(<<~JS
      const imageInput = document.getElementById('imageInput');
      const mockFile2 = new File(['mock2'], 'test_image2.png', { type: 'image/png' });
      const mockFileList2 = Object.create(FileList.prototype);
      mockFileList2[0] = mockFile2;
      Object.defineProperty(mockFileList2, 'length', { value: 1 });
      
      Object.defineProperty(imageInput, 'files', {
        value: mockFileList2,
        writable: false,
        configurable: true
      });
      
      const changeEvent = new Event('change', { bubbles: true });
      imageInput.dispatchEvent(changeEvent);
    JS
    )

    # 少し待機
    sleep 1

    # 2つのファイルが選択されていることを確認（累積されている）
    second_selection_count = page.evaluate_script("selectedFiles.length")
    assert_equal 2, second_selection_count, "2番目の選択後、selectedFilesに2個のファイルがない"

    # 3つ目の画像を選択
    page.execute_script(<<~JS
      const imageInput = document.getElementById('imageInput');
      const mockFile3 = new File(['mock3'], 'test_image3.gif', { type: 'image/gif' });
      const mockFileList3 = Object.create(FileList.prototype);
      mockFileList3[0] = mockFile3;
      Object.defineProperty(mockFileList3, 'length', { value: 1 });
      
      Object.defineProperty(imageInput, 'files', {
        value: mockFileList3,
        writable: false,
        configurable: true
      });
      
      const changeEvent = new Event('change', { bubbles: true });
      imageInput.dispatchEvent(changeEvent);
    JS
    )

    # 少し待機
    sleep 1

    # 3つのファイルが選択されていることを確認
    final_count = page.evaluate_script("selectedFiles.length")
    assert_equal 3, final_count, "3番目の選択後、selectedFilesに3個のファイルがない"

    # ファイル名が正しく保存されていることを確認
    file_names = page.evaluate_script("selectedFiles.map(f => f.name)")
    assert_includes file_names, "test_image1.jpg", "1番目のファイル名が保存されていない"
    assert_includes file_names, "test_image2.png", "2番目のファイル名が保存されていない"
    assert_includes file_names, "test_image3.gif", "3番目のファイル名が保存されていない"
  end

  test "同じファイル名の重複選択を防ぐことを確認" do
    visit_test_page

    # 同じファイルを2回選択
    2.times do |i|
      page.execute_script(<<~JS
        const imageInput = document.getElementById('imageInput');
        const mockFile = new File(['duplicate'], 'duplicate_image.jpg', { type: 'image/jpeg' });
        const mockFileList = Object.create(FileList.prototype);
        mockFileList[0] = mockFile;
        Object.defineProperty(mockFileList, 'length', { value: 1 });
        
        Object.defineProperty(imageInput, 'files', {
          value: mockFileList,
          writable: false,
          configurable: true
        });
        
        const changeEvent = new Event('change', { bubbles: true });
        imageInput.dispatchEvent(changeEvent);
      JS
      )
      sleep 1
    end

    # 重複が防がれて1つのファイルのみが保存されていることを確認
    final_count = page.evaluate_script("selectedFiles.length")
    assert_equal 1, final_count, "重複ファイルが防がれていない"
  end

  test "選択されたファイルの削除機能をテスト" do
    visit_test_page

    # 2つのファイルを選択
    page.execute_script(<<~JS
      const imageInput = document.getElementById('imageInput');
      
      // 最初のファイル
      const mockFile1 = new File(['mock1'], 'delete_test1.jpg', { type: 'image/jpeg' });
      const mockFileList1 = Object.create(FileList.prototype);
      mockFileList1[0] = mockFile1;
      Object.defineProperty(mockFileList1, 'length', { value: 1 });
      Object.defineProperty(imageInput, 'files', {
        value: mockFileList1,
        writable: false,
        configurable: true
      });
      imageInput.dispatchEvent(new Event('change', { bubbles: true }));
      
      // 少し待機してから2番目のファイル
      setTimeout(() => {
        const mockFile2 = new File(['mock2'], 'delete_test2.png', { type: 'image/png' });
        const mockFileList2 = Object.create(FileList.prototype);
        mockFileList2[0] = mockFile2;
        Object.defineProperty(mockFileList2, 'length', { value: 1 });
        Object.defineProperty(imageInput, 'files', {
          value: mockFileList2,
          writable: false,
          configurable: true
        });
        imageInput.dispatchEvent(new Event('change', { bubbles: true }));
      }, 500);
    JS
    )

    sleep 2

    # 2つのファイルが選択されていることを確認
    count_before_delete = page.evaluate_script("selectedFiles.length")
    assert_equal 2, count_before_delete, "削除テスト前に2個のファイルがない"

    # 1番目のファイルを削除
    page.execute_script("removeSelectedFile(0)")
    sleep 1

    # 1つのファイルが残っていることを確認
    count_after_delete = page.evaluate_script("selectedFiles.length")
    assert_equal 1, count_after_delete, "ファイル削除後に1個のファイルが残っていない"

    # 残っているファイル名が正しいことを確認
    remaining_file_name = page.evaluate_script("selectedFiles[0].name")
    assert_equal "delete_test2.png", remaining_file_name, "削除後に残ったファイル名が正しくない"
  end

  private

  def visit_test_page
    test_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Image Selection Fix Test</title>
      </head>
      <body>
        <input type="file" id="imageInput" accept="image/*" multiple>
        <div id="selectedFilesDisplay" style="display: none;">
          <div id="selectedFilesList"></div>
        </div>

        <script>
          // グローバル変数
          var selectedFiles = [];

          #{File.read(Rails.root.join('app/views/posts/_form_javascript.html.erb')).
            gsub(/<\/?script[^>]*>/, '').
            # handleImageUpload関数とその関連関数のみを抽出
            scan(/function handleImageUpload.*?^    }$/m).join("\n") +
            File.read(Rails.root.join('app/views/posts/_form_javascript.html.erb')).
            gsub(/<\/?script[^>]*>/, '').
            scan(/function displaySelectedFiles.*?^    }$/m).join("\n") +
            File.read(Rails.root.join('app/views/posts/_form_javascript.html.erb')).
            gsub(/<\/?script[^>]*>/, '').
            scan(/function removeSelectedFile.*?^    }$/m).join("\n") +
            File.read(Rails.root.join('app/views/posts/_form_javascript.html.erb')).
            gsub(/<\/?script[^>]*>/, '').
            scan(/function formatFileSize.*?^    }$/m).join("\n")
          }

          // イベントリスナーを設定
          document.addEventListener('DOMContentLoaded', function() {
            const imageInput = document.getElementById('imageInput');
            if (imageInput) {
              imageInput.addEventListener('change', handleImageUpload);
            }
          });
        </script>
      </body>
      </html>
    HTML

    temp_file = Rails.root.join('tmp', 'image_selection_fix_test.html')
    File.write(temp_file, test_html)
    visit "file://#{temp_file}"
  end
end