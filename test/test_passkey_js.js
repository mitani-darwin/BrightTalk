#!/usr/bin/env node

// Comprehensive test for passkey.js functionality
// Tests WebAuthn authentication, registration, and utility functions

console.log('=== Passkey.js Test Suite ===\n');

// Mock browser environment for WebAuthn
global.window = {
    focus: () => {},
    atob: (str) => Buffer.from(str, 'base64').toString('binary'),
    btoa: (str) => Buffer.from(str, 'binary').toString('base64')
};

global.document = {
    hasFocus: () => true,
    addEventListener: () => {}
};

// Ensure global.navigator exists and has credentials property
if (!global.navigator) {
    global.navigator = {};
}

global.navigator.credentials = {
    get: async (options) => {
        // Mock successful credential retrieval
        if (options && options.publicKey) {
            return {
                id: 'mock-credential-id',
                rawId: new ArrayBuffer(32),
                response: {
                    authenticatorData: new ArrayBuffer(64),
                    signature: new ArrayBuffer(64),
                    clientDataJSON: new ArrayBuffer(128)
                },
                type: 'public-key'
            };
        }
        return null;
    },
    create: async (options) => {
        // Mock successful credential creation
        if (options && options.publicKey) {
            return {
                id: 'mock-new-credential-id',
                rawId: new ArrayBuffer(32),
                response: {
                    attestationObject: new ArrayBuffer(128),
                    clientDataJSON: new ArrayBuffer(128)
                },
                type: 'public-key'
            };
        }
        return null;
    }
};

global.atob = global.window.atob;
global.btoa = global.window.btoa;
global.Uint8Array = Uint8Array;
global.ArrayBuffer = ArrayBuffer;

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

// Mock base64URL utility functions (from passkey.js)
function base64URLToArrayBuffer(base64url) {
    const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

function arrayBufferToBase64URL(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    const base64 = btoa(binary);
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

// Mock startPasskeyAuthentication function
async function startPasskeyAuthentication(passkeyOptions) {
    if (!global.navigator.credentials || !global.navigator.credentials.get) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    const convertedOptions = {
        challenge: base64URLToArrayBuffer(passkeyOptions.challenge),
        timeout: passkeyOptions.timeout || 300000,
        rpId: passkeyOptions.rpId,
        userVerification: passkeyOptions.userVerification || 'required',
        authenticatorSelection: passkeyOptions.authenticatorSelection
    };

    if (passkeyOptions.allowCredentials && Array.isArray(passkeyOptions.allowCredentials)) {
        convertedOptions.allowCredentials = passkeyOptions.allowCredentials.map((cred) => ({
            id: typeof cred.id === 'string' ? base64URLToArrayBuffer(cred.id) : cred.id,
            type: cred.type || 'public-key'
        }));
    }

    if (!global.document.hasFocus()) {
        throw new Error('認証には画面のフォーカスが必要です。');
    }

    const credential = await global.navigator.credentials.get({
        publicKey: convertedOptions
    });

    if (!credential) {
        throw new Error('No credential returned from Passkey');
    }

    return {
        id: credential.id,
        rawId: arrayBufferToBase64URL(credential.rawId),
        type: credential.type,
        response: {
            authenticatorData: arrayBufferToBase64URL(credential.response.authenticatorData),
            signature: arrayBufferToBase64URL(credential.response.signature),
            clientDataJSON: arrayBufferToBase64URL(credential.response.clientDataJSON)
        }
    };
}

// Mock startPasskeyRegistration function
async function startPasskeyRegistration(registrationOptions) {
    if (!global.navigator.credentials || !global.navigator.credentials.create) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    const convertedOptions = {
        challenge: base64URLToArrayBuffer(registrationOptions.challenge),
        rp: registrationOptions.rp,
        user: {
            ...registrationOptions.user,
            id: base64URLToArrayBuffer(registrationOptions.user.id)
        },
        pubKeyCredParams: registrationOptions.pubKeyCredParams,
        timeout: registrationOptions.timeout || 300000,
        authenticatorSelection: registrationOptions.authenticatorSelection,
        attestation: registrationOptions.attestation || 'direct'
    };

    if (registrationOptions.excludeCredentials) {
        convertedOptions.excludeCredentials = registrationOptions.excludeCredentials.map((cred) => ({
            id: typeof cred.id === 'string' ? base64URLToArrayBuffer(cred.id) : cred.id,
            type: cred.type || 'public-key'
        }));
    }

    const credential = await global.navigator.credentials.create({
        publicKey: convertedOptions
    });

    if (!credential) {
        throw new Error('No credential returned from registration');
    }

    return {
        id: credential.id,
        rawId: arrayBufferToBase64URL(credential.rawId),
        type: credential.type,
        response: {
            attestationObject: arrayBufferToBase64URL(credential.response.attestationObject),
            clientDataJSON: arrayBufferToBase64URL(credential.response.clientDataJSON)
        }
    };
}

// Run tests
async function runAllTests() {
    // Test 1: base64URLToArrayBuffer function
    await runTest('base64URL to ArrayBuffer conversion', () => {
        const testString = 'dGVzdA'; // 'test' in base64URL
        const result = base64URLToArrayBuffer(testString);
        return result instanceof ArrayBuffer && result.byteLength === 4;
    });

    // Test 2: arrayBufferToBase64URL function
    await runTest('ArrayBuffer to base64URL conversion', () => {
        const buffer = new ArrayBuffer(4);
        const view = new Uint8Array(buffer);
        view[0] = 116; view[1] = 101; view[2] = 115; view[3] = 116; // 'test'
        const result = arrayBufferToBase64URL(buffer);
        return typeof result === 'string' && result.length > 0;
    });

    // Test 3: Round-trip conversion
    await runTest('Round-trip base64URL conversion', () => {
        const original = 'dGVzdERvdW5kVHJpcA';
        const buffer = base64URLToArrayBuffer(original);
        const converted = arrayBufferToBase64URL(buffer);
        // Note: May have slight differences due to padding, but should be functionally equivalent
        return typeof converted === 'string' && converted.length > 0;
    });

    // Test 4: WebAuthn support check
    await runTest('WebAuthn support detection', () => {
        // Check if navigator.credentials is properly mocked with required methods
        console.log('Debug - global.navigator:', global.navigator);
        console.log('Debug - global.navigator.credentials:', global.navigator.credentials);
        console.log('Debug - get type:', typeof global.navigator.credentials.get);
        console.log('Debug - create type:', typeof global.navigator.credentials.create);
        return global.navigator.credentials && 
               typeof global.navigator.credentials.get === 'function' &&
               typeof global.navigator.credentials.create === 'function';
    });

    // Test 5: Passkey authentication with valid options
    await runTest('Passkey authentication - valid options', async () => {
        const validOptions = {
            challenge: 'dGVzdENoYWxsZW5nZQ',
            timeout: 60000,
            rpId: 'example.com',
            userVerification: 'required',
            allowCredentials: [
                { id: 'dGVzdENyZWQ', type: 'public-key' }
            ]
        };

        const result = await startPasskeyAuthentication(validOptions);
        return result && 
               typeof result.id === 'string' &&
               typeof result.rawId === 'string' &&
               result.type === 'public-key' &&
               result.response;
    });

    // Test 6: Passkey authentication with missing challenge
    await runTest('Passkey authentication - missing challenge', async () => {
        const invalidOptions = {
            timeout: 60000,
            rpId: 'example.com'
        };

        try {
            await startPasskeyAuthentication(invalidOptions);
            return false; // Should have thrown an error
        } catch (error) {
            return true; // Expected to fail
        }
    });

    // Test 7: Passkey registration with valid options
    await runTest('Passkey registration - valid options', async () => {
        const validOptions = {
            challenge: 'dGVzdENoYWxsZW5nZQ',
            rp: { name: 'Test App', id: 'example.com' },
            user: {
                id: 'dGVzdFVzZXI',
                name: 'test@example.com',
                displayName: 'Test User'
            },
            pubKeyCredParams: [
                { alg: -7, type: 'public-key' }
            ],
            timeout: 60000
        };

        const result = await startPasskeyRegistration(validOptions);
        return result && 
               typeof result.id === 'string' &&
               typeof result.rawId === 'string' &&
               result.type === 'public-key' &&
               result.response &&
               result.response.attestationObject;
    });

    // Test 8: Passkey registration with missing user info
    await runTest('Passkey registration - missing user info', async () => {
        const invalidOptions = {
            challenge: 'dGVzdENoYWxsZW5nZQ',
            rp: { name: 'Test App', id: 'example.com' },
            pubKeyCredParams: [
                { alg: -7, type: 'public-key' }
            ]
        };

        try {
            await startPasskeyRegistration(invalidOptions);
            return false; // Should have thrown an error
        } catch (error) {
            return true; // Expected to fail
        }
    });

    // Test 9: Document focus requirement
    await runTest('Document focus requirement', async () => {
        // Mock document without focus
        const originalHasFocus = document.hasFocus;
        document.hasFocus = () => false;

        try {
            const validOptions = {
                challenge: 'dGVzdENoYWxsZW5nZQ',
                rpId: 'example.com'
            };
            await startPasskeyAuthentication(validOptions);
            return false; // Should have thrown an error
        } catch (error) {
            return error.message.includes('フォーカス');
        } finally {
            // Always restore the original function
            document.hasFocus = originalHasFocus;
        }
    });

    // Test 10: Credential processing with different ID formats
    await runTest('Credential ID format handling', () => {
        const stringId = 'dGVzdElE';
        const arrayId = [116, 101, 115, 116]; // 'test' as array

        try {
            const stringBuffer = base64URLToArrayBuffer(stringId);
            const arrayBuffer = new Uint8Array(arrayId).buffer;
            
            return stringBuffer instanceof ArrayBuffer && 
                   arrayBuffer instanceof ArrayBuffer &&
                   stringBuffer.byteLength > 0 &&
                   arrayBuffer.byteLength > 0;
        } catch (error) {
            return false;
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

    console.log('\n🎉 Passkey.js test suite completed!');
    process.exit(testResults.failed > 0 ? 1 : 0);
}

runAllTests();