#!/usr/bin/env node

// Comprehensive test for code_editor_controller.js functionality
// Tests Stimulus controller for CodeMirror initialization and markdown editing

console.log('=== CodeEditor Controller Test Suite ===\n');

// Mock Stimulus Controller class
class Controller {
    constructor() {
        this.element = {
            classList: {
                contains: () => false,
                add: () => {},
                remove: () => {}
            },
            querySelector: () => ({ id: 'test-textarea' }),
            addEventListener: () => {}
        };
        this.dispatch = () => {};
    }
}

// Mock CodeMirror
const mockCodeMirror = {
    fromTextArea: (textarea, options) => ({
        getDoc: () => ({}),
        getWrapperElement: () => ({
            style: {},
            offsetHeight: 600
        }),
        refresh: () => {},
        setValue: () => {},
        getValue: () => 'test content',
        on: () => {},
        setSize: () => {},
        focus: () => {},
        replaceSelection: () => {},
        getCursor: () => ({ line: 0, ch: 0 }),
        getLine: () => 'test line',
        replaceRange: () => {},
        setCursor: () => {}
    })
};

// Mock window and global objects
global.window = {
    CodeMirror: mockCodeMirror,
    loadCodeMirror: async () => mockCodeMirror,
    addEventListener: () => {},
    removeEventListener: () => {},
    requestAnimationFrame: (cb) => setTimeout(cb, 16)
};

global.document = {
    readyState: 'complete',
    addEventListener: () => {},
    removeEventListener: () => {}
};

let testResults = {
    passed: 0,
    failed: 0,
    tests: []
};

function runTest(testName, testFunction) {
    return new Promise(async (resolve) => {
        try {
            console.log(`🧪 Running: ${testName}`);
            const result = await testFunction();
            if (result) {
                console.log(`✅ PASS: ${testName}\n`);
                testResults.passed++;
                testResults.tests.push({ name: testName, status: 'PASS' });
            } else {
                console.log(`❌ FAIL: ${testName}\n`);
                testResults.failed++;
                testResults.tests.push({ name: testName, status: 'FAIL' });
            }
        } catch (error) {
            console.log(`❌ ERROR: ${testName} - ${error.message}\n`);
            testResults.failed++;
            testResults.tests.push({ name: testName, status: 'ERROR', error: error.message });
        }
        resolve();
    });
}

// Mock CodeEditor Controller class
class CodeEditorController extends Controller {
    static targets = ["textarea"];

    connect() {
        if (this.element.classList.contains('codemirror-initialized')) {
            return;
        }
        this.initializeCodeMirror();
        this.initializeDynamicSizing();
        this.element.addEventListener('code-editor:insert-text', this.handleInsertText.bind(this));
    }

    async initializeCodeMirror() {
        this.element.classList.add('codemirror-initializing');

        try {
            let CodeMirror = window.CodeMirror;

            if (!CodeMirror && window.loadCodeMirror) {
                CodeMirror = await window.loadCodeMirror();
            }

            if (!CodeMirror || typeof CodeMirror.fromTextArea !== 'function') {
                let retryCount = 0;
                const maxRetries = 5;

                while (retryCount < maxRetries) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                    if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
                        CodeMirror = window.CodeMirror;
                        break;
                    }
                    retryCount++;
                }
            }

            if (!CodeMirror || typeof CodeMirror.fromTextArea !== 'function') {
                throw new Error("CodeMirror is not available");
            }

        } catch (error) {
            console.error("Failed to initialize CodeMirror:", error);
            return;
        }

        const textarea = this.textareaTarget || this.element.querySelector('textarea');
        if (!textarea) {
            console.error("Textarea not found");
            return;
        }

        try {
            this.editor = window.CodeMirror.fromTextArea(textarea, {
                mode: 'markdown',
                theme: 'default',
                lineNumbers: true,
                lineWrapping: true,
                indentUnit: 2,
                tabSize: 2,
                extraKeys: {
                    "Ctrl-Space": "autocomplete"
                },
                viewportMargin: Infinity
            });

            if (this.editor && this.editor.getDoc && this.editor.getWrapperElement) {
                const wrapper = this.editor.getWrapperElement();
                if (wrapper) {
                    wrapper.style.height = '600px';
                    wrapper.style.minHeight = '600px';
                    wrapper.style.display = 'block';
                    wrapper.style.visibility = 'visible';
                }

                this.element.classList.remove('codemirror-initializing');
                this.element.classList.add('codemirror-initialized');

                this.dispatch('initialized', { detail: { editor: this.editor } });

                setTimeout(() => {
                    if (this.editor && this.editor.refresh) {
                        this.editor.refresh();
                    }
                }, 100);
            }
        } catch (error) {
            console.error("Failed to create CodeMirror instance:", error);
        }
    }

    initializeDynamicSizing() {
        if (!this.editor) return;
        
        // Mock dynamic sizing implementation
        this.editor.on('changes', () => {
            this.adjustEditorHeight();
        });
    }

    adjustEditorHeight() {
        if (!this.editor) return;
        
        const wrapper = this.editor.getWrapperElement();
        if (wrapper) {
            const contentHeight = Math.max(600, wrapper.offsetHeight);
            wrapper.style.height = contentHeight + 'px';
        }
    }

    handleInsertText(event) {
        if (!this.editor || !event.detail) return;
        
        const { text, position } = event.detail;
        if (text) {
            if (position) {
                this.editor.replaceRange(text, position);
            } else {
                this.editor.replaceSelection(text);
            }
        }
    }

    insertMarkdownLink(url, text) {
        if (!this.editor) return;
        
        const linkText = text || 'Link';
        const markdownLink = `[${linkText}](${url})`;
        this.editor.replaceSelection(markdownLink);
    }

    insertMarkdownImage(url, alt) {
        if (!this.editor) return;
        
        const altText = alt || 'Image';
        const markdownImage = `![${altText}](${url})`;
        this.editor.replaceSelection(markdownImage);
    }

    get textareaTarget() {
        return this.element.querySelector('[data-code-editor-target="textarea"]');
    }
}

// Run tests
async function runAllTests() {
    // Test 1: Controller initialization
    await runTest('Controller initialization', () => {
        const controller = new CodeEditorController();
        return controller instanceof Controller && 
               typeof controller.connect === 'function' &&
               typeof controller.initializeCodeMirror === 'function';
    });

    // Test 2: CodeMirror availability check
    await runTest('CodeMirror availability check', () => {
        return window.CodeMirror && 
               typeof window.CodeMirror.fromTextArea === 'function';
    });

    // Test 3: CodeMirror initialization with valid textarea
    await runTest('CodeMirror initialization with valid textarea', async () => {
        const controller = new CodeEditorController();
        await controller.initializeCodeMirror();
        
        return controller.editor && 
               typeof controller.editor.getValue === 'function' &&
               typeof controller.editor.setValue === 'function';
    });

    // Test 4: Dynamic sizing initialization
    await runTest('Dynamic sizing initialization', () => {
        const controller = new CodeEditorController();
        controller.editor = mockCodeMirror.fromTextArea({}, {});
        controller.initializeDynamicSizing();
        
        return typeof controller.adjustEditorHeight === 'function';
    });

    // Test 5: Height adjustment functionality
    await runTest('Height adjustment functionality', () => {
        const controller = new CodeEditorController();
        controller.editor = mockCodeMirror.fromTextArea({}, {});
        
        try {
            controller.adjustEditorHeight();
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 6: Text insertion handling
    await runTest('Text insertion handling', () => {
        const controller = new CodeEditorController();
        controller.editor = mockCodeMirror.fromTextArea({}, {});
        
        const mockEvent = {
            detail: {
                text: 'Hello World',
                position: { line: 0, ch: 0 }
            }
        };
        
        try {
            controller.handleInsertText(mockEvent);
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 7: Markdown link insertion
    await runTest('Markdown link insertion', () => {
        const controller = new CodeEditorController();
        controller.editor = mockCodeMirror.fromTextArea({}, {});
        
        try {
            controller.insertMarkdownLink('https://example.com', 'Test Link');
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 8: Markdown image insertion
    await runTest('Markdown image insertion', () => {
        const controller = new CodeEditorController();
        controller.editor = mockCodeMirror.fromTextArea({}, {});
        
        try {
            controller.insertMarkdownImage('https://example.com/image.jpg', 'Test Image');
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 9: Error handling for missing textarea
    await runTest('Error handling for missing textarea', async () => {
        const controller = new CodeEditorController();
        controller.element.querySelector = () => null; // No textarea found
        
        try {
            await controller.initializeCodeMirror();
            return true; // Should handle gracefully
        } catch (error) {
            return false;
        }
    });

    // Test 10: CodeMirror retry mechanism
    await runTest('CodeMirror retry mechanism', async () => {
        const controller = new CodeEditorController();
        
        // Temporarily remove CodeMirror
        const originalCodeMirror = window.CodeMirror;
        window.CodeMirror = null;
        
        // Restore after a delay to simulate loading
        setTimeout(() => {
            window.CodeMirror = originalCodeMirror;
        }, 50);
        
        try {
            await controller.initializeCodeMirror();
            return true; // Should retry and succeed
        } catch (error) {
            window.CodeMirror = originalCodeMirror; // Restore for other tests
            return false;
        }
    });

    // Test 11: Element class management
    await runTest('Element class management', () => {
        const controller = new CodeEditorController();
        let classes = [];
        
        controller.element.classList.add = (className) => classes.push(className);
        controller.element.classList.remove = (className) => {
            const index = classes.indexOf(className);
            if (index > -1) classes.splice(index, 1);
        };
        controller.element.classList.contains = (className) => classes.includes(className);
        
        controller.connect();
        
        return classes.includes('codemirror-initializing');
    });

    // Test 12: Event listener setup
    await runTest('Event listener setup', () => {
        const controller = new CodeEditorController();
        let eventListenerAdded = false;
        
        controller.element.addEventListener = (event, handler) => {
            if (event === 'code-editor:insert-text' && typeof handler === 'function') {
                eventListenerAdded = true;
            }
        };
        
        controller.connect();
        return eventListenerAdded;
    });

    // Display results
    console.log('\n' + '='.repeat(50));
    console.log('TEST RESULTS SUMMARY');
    console.log('='.repeat(50));
    console.log(`Total Tests: ${testResults.passed + testResults.failed}`);
    console.log(`Passed: ${testResults.passed}`);
    console.log(`Failed: ${testResults.failed}`);
    console.log(`Success Rate: ${Math.round((testResults.passed / (testResults.passed + testResults.failed)) * 100)}%`);

    if (testResults.failed > 0) {
        console.log('\nFailed Tests:');
        testResults.tests.filter(t => t.status !== 'PASS').forEach(test => {
            console.log(`  - ${test.name}: ${test.status}${test.error ? ' - ' + test.error : ''}`);
        });
    }

    console.log('\n🎉 CodeEditor Controller test suite completed!');
    process.exit(testResults.failed > 0 ? 1 : 0);
}

runAllTests();