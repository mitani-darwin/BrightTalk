
function startWebAuthnAuthentication(webauthnOptions) {
    console.log('WebAuthn authentication options received:', webauthnOptions);

    if (!webauthnOptions || !webauthnOptions.challenge) {
        throw new Error('Invalid WebAuthn options');
    }

    // WebAuthnオプションを変換
    const convertedOptions = {
        challenge: base64URLToArrayBuffer(webauthnOptions.challenge),
        timeout: webauthnOptions.timeout || 60000,
        userVerification: 'required' // Touch IDを強制
    };

    // allowCredentialsを空にして、Touch IDなどの内蔵認証器を使用
    convertedOptions.allowCredentials = [];

    console.log('Converted WebAuthn authentication options:', convertedOptions);

    // WebAuthn認証実行
    return navigator.credentials.get({
        publicKey: convertedOptions
    });
}

// Base64URL文字列をArrayBufferに変換する関数（改良版）
function base64URLToArrayBuffer(base64url) {
    // 入力値検証
    if (!base64url || typeof base64url !== 'string') {
        throw new Error('Invalid base64url input');
    }

    try {
        // Base64URLからBase64に変換
        let base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');

        // パディングを追加
        const padLength = (4 - base64.length % 4) % 4;
        base64 += '='.repeat(padLength);

        // Base64デコード前の検証
        if (!/^[A-Za-z0-9+/]*=*$/.test(base64)) {
            throw new Error('Invalid base64 string');
        }

        // Base64をデコード
        const binaryString = atob(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    } catch (error) {
        console.error('Base64URL decode error:', error);
        console.error('Input value:', base64url);
        throw new Error(`Base64URL decode failed: ${error.message}`);
    }
}

// ArrayBufferをBase64URL文字列に変換する関数
function arrayBufferToBase64URL(buffer) {
    if (!buffer) {
        return '';
    }

    try {
        const bytes = new Uint8Array(buffer);
        let binary = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        const base64 = btoa(binary);
        return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
    } catch (error) {
        console.error('Base64URL encode error:', error);
        throw new Error(`Base64URL encode failed: ${error.message}`);
    }
}

// デバッグ用の関数
function debugBase64URL(value, name = 'value') {
    console.log(`Debug ${name}:`, value);
    console.log(`Type:`, typeof value);
    console.log(`Length:`, value ? value.length : 'N/A');

    if (typeof value === 'string') {
        // Base64URL文字の検証
        const validChars = /^[A-Za-z0-9_-]*$/;
        console.log(`Valid Base64URL chars:`, validChars.test(value));

        // 各文字のASCII値を表示（最初の10文字のみ）
        const chars = value.substring(0, 10).split('').map(c => `${c}(${c.charCodeAt(0)})`);
        console.log(`First 10 chars:`, chars.join(', '));
    }
}

// エラーハンドリング付きのBase64URL変換関数
function safeBase64URLToArrayBuffer(base64url) {
    try {
        debugBase64URL(base64url, 'input');
        const result = base64URLToArrayBuffer(base64url);
        console.log('Conversion successful, buffer length:', result.byteLength);
        return result;
    } catch (error) {
        console.error('Safe conversion failed:', error);
        // フォールバック処理：空のArrayBufferを返す
        return new ArrayBuffer(0);
    }
}