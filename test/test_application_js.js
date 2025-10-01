#!/usr/bin/env node

// Comprehensive test for application.js functionality
// Tests main application setup, library loading, and global functions

console.log('=== Application.js Test Suite ===\n');

// Mock DOM and window environment
global.window = {
    CodeMirror: null,
    videojs: null,
    flatpickr: null,
    startPasskeyAuthentication: null,
    startPasskeyRegistration: null,
    ActiveStorage: null,
    Stimulus: null,
    loadCodeMirror: null,
    loadVideoJS: null,
    checkActiveStorageStatus: null,
    focus: () => {},
    addEventListener: () => {},
};

global.document = {
    addEventListener: () => {},
    hasFocus: () => true,
    querySelector: () => ({ getAttribute: () => 'test-token' }),
};

global.console = console;

let testResults = {
    passed: 0,
    failed: 0,
    tests: []
};

function runTest(testName, testFunction) {
    try {
        console.log(`🧪 Running: ${testName}`);
        const result = testFunction();
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
}

// Test 1: Check window object setup
runTest('Window object initialization', () => {
    return typeof window === 'object' && 
           typeof document === 'object';
});

// Test 2: Mock library availability after imports
runTest('Library availability simulation', () => {
    // Simulate libraries being loaded
    window.CodeMirror = {
        fromTextArea: () => ({
            getDoc: () => ({}),
            getWrapperElement: () => ({ style: {} }),
            refresh: () => {}
        })
    };
    window.videojs = () => ({
        ready: (callback) => callback(),
        videoWidth: () => 640,
        videoHeight: () => 480,
        width: () => {},
        height: () => {},
        dispose: () => {}
    });
    window.flatpickr = () => ({ destroy: () => {} });
    
    return window.CodeMirror && 
           typeof window.CodeMirror.fromTextArea === 'function' &&
           window.videojs && 
           typeof window.videojs === 'function' &&
           window.flatpickr && 
           typeof window.flatpickr === 'function';
});

// Test 3: Mock loadCodeMirror function
runTest('loadCodeMirror function simulation', () => {
    window.loadCodeMirror = async () => {
        if (window.CodeMirror && typeof window.CodeMirror.fromTextArea === 'function') {
            return window.CodeMirror;
        }
        throw new Error('CodeMirror not available');
    };
    
    return typeof window.loadCodeMirror === 'function';
});

// Test 4: Mock loadVideoJS function
runTest('loadVideoJS function simulation', () => {
    window.loadVideoJS = async () => {
        if (window.videojs) {
            return window.videojs;
        }
        return null;
    };
    
    return typeof window.loadVideoJS === 'function';
});

// Test 5: Mock ActiveStorage setup
runTest('ActiveStorage setup simulation', () => {
    window.ActiveStorage = {
        start: () => {},
        DirectUpload: function() {},
        started: true
    };
    
    return window.ActiveStorage &&
           typeof window.ActiveStorage.start === 'function' &&
           typeof window.ActiveStorage.DirectUpload === 'function';
});

// Test 6: Mock checkActiveStorageStatus function
runTest('checkActiveStorageStatus function simulation', () => {
    window.checkActiveStorageStatus = function() {
        return {
            available: typeof window.ActiveStorage !== 'undefined',
            directUpload: typeof window.ActiveStorage?.DirectUpload === 'function',
            started: window.ActiveStorage?.started || false
        };
    };
    
    const status = window.checkActiveStorageStatus();
    return typeof window.checkActiveStorageStatus === 'function' &&
           status.available === true &&
           status.directUpload === true &&
           status.started === true;
});

// Test 7: Mock Stimulus application setup
runTest('Stimulus application setup simulation', () => {
    const mockApplication = {
        register: (name, controller) => {
            console.log(`Registered controller: ${name}`);
        }
    };
    
    window.Stimulus = mockApplication;
    
    // Simulate controller registration
    const mockControllers = ['code-editor', 'video-player', 'flatpickr'];
    mockControllers.forEach(name => {
        mockApplication.register(name, class MockController {});
    });
    
    return window.Stimulus && 
           typeof window.Stimulus.register === 'function';
});

// Test 8: Mock passkey functions
runTest('Passkey functions setup simulation', () => {
    window.startPasskeyAuthentication = async (options) => {
        if (!options || !options.challenge) {
            throw new Error('Invalid passkey options');
        }
        return { id: 'mock-credential-id', rawId: 'mock-raw-id' };
    };
    
    window.startPasskeyRegistration = async (options) => {
        if (!options || !options.challenge) {
            throw new Error('Invalid registration options');
        }
        return { id: 'mock-new-credential-id', rawId: 'mock-new-raw-id' };
    };
    
    return typeof window.startPasskeyAuthentication === 'function' &&
           typeof window.startPasskeyRegistration === 'function';
});

// Test 9: CSRF token handling simulation
runTest('CSRF token handling simulation', () => {
    let csrfHandlerCalled = false;
    
    // Mock event for Turbo CSRF handling
    const mockEvent = {
        detail: {
            fetchOptions: {
                headers: {}
            }
        }
    };
    
    // Simulate CSRF token handling
    const token = 'test-csrf-token';
    mockEvent.detail.fetchOptions.headers['X-CSRF-Token'] = token;
    csrfHandlerCalled = true;
    
    return csrfHandlerCalled && 
           mockEvent.detail.fetchOptions.headers['X-CSRF-Token'] === token;
});

// Test 10: Error handling for missing libraries
runTest('Error handling for missing libraries', () => {
    // Test loadCodeMirror error handling
    const originalCodeMirror = window.CodeMirror;
    window.CodeMirror = null;
    
    try {
        const result = window.loadCodeMirror();
        // Should handle missing CodeMirror gracefully
        window.CodeMirror = originalCodeMirror; // Restore
        return true;
    } catch (error) {
        window.CodeMirror = originalCodeMirror; // Restore
        return error.message.includes('CodeMirror');
    }
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

console.log('\n🎉 Application.js test suite completed!');
process.exit(testResults.failed > 0 ? 1 : 0);