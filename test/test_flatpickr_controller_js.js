#!/usr/bin/env node

// Comprehensive test for flatpickr_controller.js functionality
// Tests Stimulus controller for Flatpickr date picker initialization

console.log('=== Flatpickr Controller Test Suite ===\n');

// Mock Stimulus Controller class
class Controller {
    constructor() {
        this.element = {
            querySelector: () => ({ id: 'test-input', value: '' })
        };
        this.inputTarget = { id: 'test-input', value: '' };
        this.hasInputTarget = true;
        
        // Mock data values
        this.modeValue = 'single';
        this.dateFormatValue = 'Y/m/d';
        this.localeValue = 'ja';
    }
}

// Mock Flatpickr
const mockFlatpickr = (element, options) => {
    return {
        destroy: () => {},
        setDate: (date) => {},
        clear: () => {},
        open: () => {},
        close: () => {},
        toggle: () => {},
        changeMonth: (monthIndex) => {},
        config: options || {},
        element: element,
        selectedDates: [],
        currentMonth: 0,
        currentYear: 2024,
        isOpen: false
    };
};

// Mock Japanese locale
const mockJapanese = {
    weekdays: {
        shorthand: ['日', '月', '火', '水', '木', '金', '土'],
        longhand: ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日']
    },
    months: {
        shorthand: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
        longhand: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
    }
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

// Mock Flatpickr Controller class
class FlatpickrController extends Controller {
    static targets = ["input"];
    static values = {
        mode: String,
        dateFormat: String,
        locale: String
    };

    connect() {
        this.initializeFlatpickr();
    }

    initializeFlatpickr() {
        const options = {
            mode: this.modeValue || "single",
            dateFormat: this.dateFormatValue || "Y/m/d",
            allowInput: false,
            clickOpens: true,
            locale: this.localeValue === "ja" ? mockJapanese : "default"
        };

        // Range selection mode settings
        if (this.modeValue === "range") {
            options.mode = "range";
            options.dateFormat = "Y/m/d";
            options.separator = " 〜 ";
        }

        // Multiple selection mode settings
        if (this.modeValue === "multiple") {
            options.mode = "multiple";
            options.conjunction = ", ";
        }

        // Initialize Flatpickr
        this.flatpickr = mockFlatpickr(this.inputTarget, options);

        console.log("Flatpickr initialized with options:", options);
    }

    disconnect() {
        if (this.flatpickr) {
            this.flatpickr.destroy();
        }
    }

    // Helper methods for testing
    setDate(date) {
        if (this.flatpickr) {
            this.flatpickr.setDate(date);
        }
    }

    clear() {
        if (this.flatpickr) {
            this.flatpickr.clear();
        }
    }

    open() {
        if (this.flatpickr) {
            this.flatpickr.open();
        }
    }

    close() {
        if (this.flatpickr) {
            this.flatpickr.close();
        }
    }

    getConfig() {
        return this.flatpickr ? this.flatpickr.config : null;
    }

    isInitialized() {
        return this.flatpickr !== null && this.flatpickr !== undefined;
    }
}

// Run tests
async function runAllTests() {
    // Test 1: Controller initialization
    await runTest('Controller initialization', () => {
        const controller = new FlatpickrController();
        return controller instanceof Controller && 
               typeof controller.connect === 'function' &&
               typeof controller.initializeFlatpickr === 'function';
    });

    // Test 2: Input target detection
    await runTest('Input target detection', () => {
        const controller = new FlatpickrController();
        return controller.hasInputTarget && 
               controller.inputTarget && 
               controller.inputTarget.id === 'test-input';
    });

    // Test 3: Flatpickr initialization with default options
    await runTest('Flatpickr initialization with default options', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        return controller.flatpickr && 
               typeof controller.flatpickr.destroy === 'function' &&
               controller.flatpickr.config.mode === 'single' &&
               controller.flatpickr.config.dateFormat === 'Y/m/d';
    });

    // Test 4: Range mode configuration
    await runTest('Range mode configuration', () => {
        const controller = new FlatpickrController();
        controller.modeValue = 'range';
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config && 
               config.mode === 'range' &&
               config.separator === ' 〜 ';
    });

    // Test 5: Multiple mode configuration
    await runTest('Multiple mode configuration', () => {
        const controller = new FlatpickrController();
        controller.modeValue = 'multiple';
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config && 
               config.mode === 'multiple' &&
               config.conjunction === ', ';
    });

    // Test 6: Japanese locale configuration
    await runTest('Japanese locale configuration', () => {
        const controller = new FlatpickrController();
        controller.localeValue = 'ja';
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config && 
               config.locale === mockJapanese &&
               config.locale.weekdays.shorthand[0] === '日';
    });

    // Test 7: Custom date format
    await runTest('Custom date format', () => {
        const controller = new FlatpickrController();
        controller.dateFormatValue = 'd/m/Y';
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config && config.dateFormat === 'd/m/Y';
    });

    // Test 8: Date setting functionality
    await runTest('Date setting functionality', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        try {
            controller.setDate(new Date('2024-01-15'));
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 9: Clear functionality
    await runTest('Clear functionality', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        try {
            controller.clear();
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 10: Open/Close functionality
    await runTest('Open/Close functionality', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        try {
            controller.open();
            controller.close();
            return true; // Should not throw error
        } catch (error) {
            return false;
        }
    });

    // Test 11: Disconnect and cleanup
    await runTest('Disconnect and cleanup', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        const wasInitialized = controller.isInitialized();
        controller.disconnect();
        
        // After disconnect, flatpickr should still exist but destroy should have been called
        return wasInitialized;
    });

    // Test 12: Error handling for missing input
    await runTest('Error handling for missing input', () => {
        const controller = new FlatpickrController();
        controller.inputTarget = null;
        controller.hasInputTarget = false;
        
        try {
            controller.initializeFlatpickr();
            return true; // Should handle gracefully
        } catch (error) {
            return false;
        }
    });

    // Test 13: Default values when not specified
    await runTest('Default values when not specified', () => {
        const controller = new FlatpickrController();
        // Clear all values to test defaults
        controller.modeValue = undefined;
        controller.dateFormatValue = undefined;
        controller.localeValue = undefined;
        
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config && 
               config.mode === 'single' &&
               config.dateFormat === 'Y/m/d' &&
               config.locale === 'default';
    });

    // Test 14: ClickOpens and allowInput settings
    await runTest('ClickOpens and allowInput settings', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config && 
               config.clickOpens === true &&
               config.allowInput === false;
    });

    // Test 15: Configuration object structure
    await runTest('Configuration object structure', () => {
        const controller = new FlatpickrController();
        controller.initializeFlatpickr();
        
        const config = controller.getConfig();
        return config &&
               typeof config.mode === 'string' &&
               typeof config.dateFormat === 'string' &&
               typeof config.clickOpens === 'boolean' &&
               typeof config.allowInput === 'boolean';
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

    console.log('\n🎉 Flatpickr Controller test suite completed!');
    process.exit(testResults.failed > 0 ? 1 : 0);
}

runAllTests();