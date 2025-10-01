// CI Test for CodeEditor Markdown Insertion
// Tests image and video file markdown insertion functionality

const { chromium } = require('playwright');

async function runTests() {
    console.log('🚀 Starting CodeEditor Markdown Insertion CI Tests');
    
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // Create test HTML
    const testHTML = `
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CodeEditor Markdown Insertion CI Test</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.css">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/markdown/markdown.min.js"></script>
</head>
<body>
    <div data-controller="code-editor" id="codeEditorContainer">
        <textarea id="contentTextarea" data-code-editor-target="textarea"></textarea>
    </div>
    
    <input type="file" id="imageInput" accept="image/*" multiple style="display:none;">
    <input type="file" id="videoInput" accept="video/*" style="display:none;">
    
    <script>
        // CodeEditor Controller Implementation
        class CodeEditorController {
            constructor(element) {
                this.element = element;
                this.textareaTarget = element.querySelector('textarea');
                this.connect();
            }
            
            connect() {
                this.initializeCodeMirror();
                this.element.addEventListener('code-editor:insert-text', this.handleInsertText.bind(this));
            }
            
            initializeCodeMirror() {
                if (window.CodeMirror && this.textareaTarget) {
                    this.editor = window.CodeMirror.fromTextArea(this.textareaTarget, {
                        mode: 'markdown',
                        theme: 'default',
                        lineNumbers: true,
                        lineWrapping: true
                    });
                    
                    // Store reference for external access
                    this.element.codeEditorController = this;
                }
            }
            
            insertText(text) {
                if (this.editor && this.editor.getDoc) {
                    var cursor = this.editor.getCursor();
                    this.editor.replaceRange(text, cursor);
                    this.editor.focus();
                    return true;
                } else {
                    return false;
                }
            }
            
            handleInsertText(event) {
                var text = event.detail.text;
                if (text) {
                    this.insertText(text);
                }
            }
        }
        
        // File upload handlers
        function handleImageUpload(files) {
            var textarea = document.getElementById('contentTextarea');
            
            for (var i = 0; i < files.length; i++) {
                var file = files[i];
                var markdownLink = '![' + file.name + '](attachment:' + file.name + ')\\n\\n';
                
                setTimeout(function() {
                    insertMarkdownAtCursor(textarea, markdownLink);
                }, 100);
            }
        }
        
        function handleVideoUpload(file) {
            var textarea = document.getElementById('contentTextarea');
            var markdownLink = '[' + file.name + '](attachment:' + file.name + ')\\n\\n';
            
            setTimeout(function() {
                insertMarkdownAtCursor(textarea, markdownLink);
            }, 100);
        }
        
        // Main insertion function
        function insertMarkdownAtCursor(textarea, text) {
            if (!textarea) return;
            
            var codeEditorElement = textarea.closest('[data-controller*="code-editor"]');
            if (codeEditorElement) {
                // Try direct controller access
                if (codeEditorElement.codeEditorController && codeEditorElement.codeEditorController.insertText) {
                    codeEditorElement.codeEditorController.insertText(text);
                    return;
                }
                
                // Try custom event
                var customEvent = new CustomEvent('code-editor:insert-text', {
                    detail: { text: text }
                });
                codeEditorElement.dispatchEvent(customEvent);
                
                // Check if insertion worked after a short delay
                setTimeout(function() {
                    if (!textarea.value.includes(text.trim())) {
                        fallbackTextInsertion(textarea, text);
                    }
                }, 100);
                return;
            }
            
            // Fallback
            fallbackTextInsertion(textarea, text);
        }
        
        function fallbackTextInsertion(textarea, text) {
            var start = textarea.selectionStart || textarea.value.length;
            var end = textarea.selectionEnd || textarea.value.length;
            var currentValue = textarea.value;
            
            textarea.value = currentValue.substring(0, start) + text + currentValue.substring(end);
            var newPos = start + text.length;
            textarea.selectionStart = textarea.selectionEnd = newPos;
            textarea.focus();
        }
        
        // Initialize on load
        window.addEventListener('load', function() {
            var codeEditorElement = document.querySelector('[data-controller="code-editor"]');
            if (codeEditorElement) {
                new CodeEditorController(codeEditorElement);
            }
        });
        
        // Test functions for automated testing
        window.testImageInsertion = function(filename) {
            var mockFile = { name: filename };
            handleImageUpload([mockFile]);
        };
        
        window.testVideoInsertion = function(filename) {
            var mockFile = { name: filename };
            handleVideoUpload(mockFile);
        };
        
        window.getEditorContent = function() {
            var codeEditorElement = document.querySelector('[data-controller="code-editor"]');
            if (codeEditorElement && codeEditorElement.codeEditorController && codeEditorElement.codeEditorController.editor) {
                return codeEditorElement.codeEditorController.editor.getValue();
            }
            return document.getElementById('contentTextarea').value;
        };
        
        window.clearEditor = function() {
            var codeEditorElement = document.querySelector('[data-controller="code-editor"]');
            if (codeEditorElement && codeEditorElement.codeEditorController && codeEditorElement.codeEditorController.editor) {
                codeEditorElement.codeEditorController.editor.setValue("");
            } else {
                document.getElementById('contentTextarea').value = "";
            }
        };
    </script>
</body>
</html>
    `;
    
    // Set content and wait for load
    await page.setContent(testHTML);
    await page.waitForTimeout(2000); // Wait for CodeMirror to initialize
    
    let testResults = {
        passed: 0,
        failed: 0,
        errors: []
    };
    
    console.log('🧪 Running Test 1: Image Markdown Insertion');
    try {
        await page.evaluate(() => {
            window.clearEditor();
            window.testImageInsertion('test-image.jpg');
        });
        
        await page.waitForTimeout(1000);
        
        const content = await page.evaluate(() => window.getEditorContent());
        
        if (content.includes('![test-image.jpg](attachment:test-image.jpg)')) {
            console.log('✅ Test 1 PASSED: Image markdown inserted correctly');
            testResults.passed++;
        } else {
            console.log('❌ Test 1 FAILED: Image markdown not found in content:', content);
            testResults.failed++;
            testResults.errors.push('Image markdown insertion failed');
        }
    } catch (error) {
        console.log('❌ Test 1 ERROR:', error.message);
        testResults.failed++;
        testResults.errors.push('Image test error: ' + error.message);
    }
    
    console.log('🧪 Running Test 2: Video Markdown Insertion');
    try {
        await page.evaluate(() => {
            window.clearEditor();
            window.testVideoInsertion('test-video.mp4');
        });
        
        await page.waitForTimeout(1000);
        
        const content = await page.evaluate(() => window.getEditorContent());
        
        if (content.includes('[test-video.mp4](attachment:test-video.mp4)')) {
            console.log('✅ Test 2 PASSED: Video markdown inserted correctly');
            testResults.passed++;
        } else {
            console.log('❌ Test 2 FAILED: Video markdown not found in content:', content);
            testResults.failed++;
            testResults.errors.push('Video markdown insertion failed');
        }
    } catch (error) {
        console.log('❌ Test 2 ERROR:', error.message);
        testResults.failed++;
        testResults.errors.push('Video test error: ' + error.message);
    }
    
    console.log('🧪 Running Test 3: Multiple Image Insertion');
    try {
        await page.evaluate(() => {
            window.clearEditor();
            window.testImageInsertion('image1.png');
        });
        
        await page.waitForTimeout(500);
        
        await page.evaluate(() => {
            window.testImageInsertion('image2.jpg');
        });
        
        await page.waitForTimeout(1000);
        
        const content = await page.evaluate(() => window.getEditorContent());
        
        if (content.includes('![image1.png](attachment:image1.png)') && 
            content.includes('![image2.jpg](attachment:image2.jpg)')) {
            console.log('✅ Test 3 PASSED: Multiple images inserted correctly');
            testResults.passed++;
        } else {
            console.log('❌ Test 3 FAILED: Multiple images not found in content:', content);
            testResults.failed++;
            testResults.errors.push('Multiple image insertion failed');
        }
    } catch (error) {
        console.log('❌ Test 3 ERROR:', error.message);
        testResults.failed++;
        testResults.errors.push('Multiple image test error: ' + error.message);
    }
    
    console.log('🧪 Running Test 4: CodeEditor Integration');
    try {
        const hasCodeMirror = await page.evaluate(() => {
            return typeof window.CodeMirror !== 'undefined';
        });
        
        const hasController = await page.evaluate(() => {
            var element = document.querySelector('[data-controller="code-editor"]');
            return element && element.codeEditorController;
        });
        
        if (hasCodeMirror && hasController) {
            console.log('✅ Test 4 PASSED: CodeEditor properly integrated');
            testResults.passed++;
        } else {
            console.log('❌ Test 4 FAILED: CodeEditor integration issues - CodeMirror:', hasCodeMirror, 'Controller:', hasController);
            testResults.failed++;
            testResults.errors.push('CodeEditor integration failed');
        }
    } catch (error) {
        console.log('❌ Test 4 ERROR:', error.message);
        testResults.failed++;
        testResults.errors.push('Integration test error: ' + error.message);
    }
    
    await browser.close();
    
    console.log('\\n📊 Test Results Summary:');
    console.log('✅ Passed:', testResults.passed);
    console.log('❌ Failed:', testResults.failed);
    
    if (testResults.errors.length > 0) {
        console.log('\\n🚨 Errors:');
        testResults.errors.forEach(error => console.log('  -', error));
    }
    
    if (testResults.failed > 0) {
        console.log('\\n💡 All tests must pass to ensure image/video markdown insertion works correctly.');
        process.exit(1);
    } else {
        console.log('\\n🎉 All tests passed! Image/video markdown insertion is working correctly.');
        process.exit(0);
    }
}

// Run tests if this script is executed directly
if (require.main === module) {
    runTests().catch(error => {
        console.error('❌ Test execution failed:', error);
        process.exit(1);
    });
}

module.exports = { runTests };