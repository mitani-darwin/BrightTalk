require "application_system_test_case"

class VideoUploadCodeeditorTest < ApplicationSystemTestCase
  setup do
    @user = users(:test_user)
    @post = posts(:first_post)
    @post.update!(user: @user)
  end

  test "動画選択時にCodeEditorにMarkdownが挿入される" do
    login_as(@user)
    visit edit_post_path(@post)

    # CodeEditorが正しく初期化されていることを確認
    assert_selector "[data-controller*='code-editor']"
    assert_selector "#contentTextarea"

    # 動画ファイル選択要素が存在することを確認
    assert_selector "#videoInput"

    # JavaScript関数が正しく定義されていることを確認
    assert page.evaluate_script("typeof handleVideoUpload === 'function'")
    assert page.evaluate_script("typeof insertMarkdownAtCursor === 'function'")

    # CodeEditorが初期化されるまで少し待機
    sleep 1

    # CodeEditorコントローラーが正しく動作していることを確認
    codeeditor_initialized = page.evaluate_script(<<~JS
      const textarea = document.getElementById('contentTextarea');
      const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      return !!codeEditorElement;
    JS
    )
    assert codeeditor_initialized, "CodeEditor element should exist"

    # 動画ファイルを選択する（実際のファイルアップロードをシミュレート）
    page.execute_script(<<~JS
      const videoInput = document.getElementById('videoInput');
      const mockFile = new File(['mock video content'], 'test_video.mp4', { type: 'video/mp4' });
      const mockFileList = Object.create(FileList.prototype);
      mockFileList[0] = mockFile;
      Object.defineProperty(mockFileList, 'length', { value: 1 });
      
      Object.defineProperty(videoInput, 'files', {
        value: mockFileList,
        writable: false
      });
      
      // changeイベントを発火
      const changeEvent = new Event('change', { bubbles: true });
      videoInput.dispatchEvent(changeEvent);
    JS
    )

    # テキストが挿入されるまで少し待機
    sleep 1

    # CodeEditorにMarkdownリンクが挿入されたことを確認
    content_value = page.evaluate_script(<<~JS
      const textarea = document.getElementById('contentTextarea');
      const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      // CodeMirrorエディターから値を取得
      if (window.CodeMirror && codeEditorElement) {
        const editor = codeEditorElement.querySelector('.CodeMirror');
        if (editor && editor.CodeMirror) {
          return editor.CodeMirror.getValue();
        }
      }
      
      // フォールバック: 通常のテキストエリアの値
      return textarea.value;
    JS
    )

    assert content_value.include?("[test_video.mp4]"), "動画のMarkdownリンクが挿入されていません: #{content_value}"
    assert content_value.include?("attachment:test_video.mp4"), "動画のattachmentリンクが正しく生成されていません: #{content_value}"
  end

  test "既存動画の挿入ボタンが正常に動作する" do
    login_as(@user)
    
    # 動画付きの投稿を作成
    @post.videos.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_video.mp4")),
      filename: "existing_video.mp4",
      content_type: "video/mp4"
    )

    visit edit_post_path(@post)

    # 既存動画の挿入ボタンが表示されることを確認
    assert_selector ".insert-existing-video", text: "挿入"

    # CodeEditorが初期化されるまで少し待機
    sleep 1

    # 挿入ボタンをクリック
    first(".insert-existing-video").click

    # テキスト挿入まで少し待機
    sleep 1

    # エディターに動画リンクが挿入されたことを確認
    content_value = page.evaluate_script(<<~JS
      const textarea = document.getElementById('contentTextarea');
      const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      if (window.CodeMirror && codeEditorElement) {
        const editor = codeEditorElement.querySelector('.CodeMirror');
        if (editor && editor.CodeMirror) {
          return editor.CodeMirror.getValue();
        }
      }
      
      return textarea.value;
    JS
    )

    assert content_value.include?("existing_video.mp4"), "既存動画のリンクが挿入されていません: #{content_value}"
  end

  test "CodeEditor未初期化時のフォールバック動作" do
    login_as(@user)
    visit edit_post_path(@post)

    # CodeMirrorを一時的に無効化
    page.execute_script("window.CodeMirror = undefined;")

    # テキストエリアが存在することを確認
    assert_selector "#contentTextarea"

    # 動画選択をシミュレート
    page.execute_script(<<~JS
      const videoInput = document.getElementById('videoInput');
      const mockFile = new File(['mock video content'], 'fallback_test.mp4', { type: 'video/mp4' });
      const mockFileList = Object.create(FileList.prototype);
      mockFileList[0] = mockFile;
      Object.defineProperty(mockFileList, 'length', { value: 1 });
      
      Object.defineProperty(videoInput, 'files', {
        value: mockFileList,
        writable: false
      });
      
      const changeEvent = new Event('change', { bubbles: true });
      videoInput.dispatchEvent(changeEvent);
    JS
    )

    # フォールバック処理が完了するまで待機
    sleep 1

    # 通常のテキストエリアにテキストが挿入されたことを確認
    textarea_value = page.evaluate_script("document.getElementById('contentTextarea').value")
    assert textarea_value.include?("fallback_test.mp4"), "フォールバックでのテキスト挿入が失敗しました: #{textarea_value}"
  end

  test "insertMarkdownAtCursor関数の複数の取得方法をテスト" do
    login_as(@user)
    visit edit_post_path(@post)

    # CodeEditorの初期化を待機
    sleep 1

    # 各取得方法をテスト
    controller_test_result = page.evaluate_script(<<~JS
      const textarea = document.getElementById('contentTextarea');
      const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      let results = {
        elementFound: !!codeEditorElement,
        stimulusApp: !!(window.Stimulus || window.Application),
        elementController: !!(codeEditorElement && codeEditorElement.controller),
        stimulusControllers: !!(codeEditorElement && codeEditorElement._stimulus_controllers),
        customEventSupported: true
      };
      
      // カスタムイベントのテスト
      if (codeEditorElement) {
        const customEvent = new CustomEvent('code-editor:insert-text', {
          detail: { text: 'Test insertion via custom event\\n\\n' }
        });
        codeEditorElement.dispatchEvent(customEvent);
      }
      
      return results;
    JS
    )

    assert controller_test_result['elementFound'], "code-editor要素が見つかりません"
    assert controller_test_result['customEventSupported'], "カスタムイベントがサポートされていません"

    # カスタムイベントでのテキスト挿入を確認
    sleep 1
    
    final_content = page.evaluate_script(<<~JS
      const textarea = document.getElementById('contentTextarea');
      const codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
      
      if (window.CodeMirror && codeEditorElement) {
        const editor = codeEditorElement.querySelector('.CodeMirror');
        if (editor && editor.CodeMirror) {
          return editor.CodeMirror.getValue();
        }
      }
      
      return textarea.value;
    JS
    )

    assert final_content.include?("Test insertion via custom event"), "カスタムイベントによるテキスト挿入が失敗しました: #{final_content}"
  end

end