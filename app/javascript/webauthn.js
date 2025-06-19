// Base64URL変換関数
function base64URLToArrayBuffer(base64url) {
    // Base64URLをBase64に変換
    let base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
    // パディングを追加
    while (base64.length % 4) {
        base64 += '=';
    }

    try {
        const binaryString = atob(base64);
        const len = binaryString.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    } catch (e) {
        console.error('Base64URL decode error:', e);
        throw new Error('Invalid base64url string');
    }
}

function arrayBufferToBase64URL(buffer) {
    const bytes = new Uint8Array(buffer);
    let binaryString = '';
    for (let i = 0; i < bytes.byteLength; i++) {
        binaryString += String.fromCharCode(bytes[i]);
    }
    const base64 = btoa(binaryString);
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

// WebAuthn登録の開始
function startWebAuthnRegistration(webauthnOptions) {
    console.log('WebAuthn registration page loaded');

    if (!navigator.credentials || !navigator.credentials.create) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    console.log('WebAuthn options:', webauthnOptions);

    // WebAuthnオプションの変換
    const convertedOptions = {
        challenge: base64URLToArrayBuffer(webauthnOptions.challenge),
        rp: webauthnOptions.rp,
        user: {
            id: base64URLToArrayBuffer(webauthnOptions.user.id),
            name: webauthnOptions.user.name,
            displayName: webauthnOptions.user.displayName
        },
        pubKeyCredParams: webauthnOptions.pubKeyCredParams,
        timeout: webauthnOptions.timeout,
        attestation: webauthnOptions.attestation || 'direct',
        authenticatorSelection: {
            authenticatorAttachment: 'platform', // Touch ID/Face IDを優先
            userVerification: 'required'
        }
    };

    // excludeCredentialsがある場合は変換
    if (webauthnOptions.excludeCredentials && webauthnOptions.excludeCredentials.length > 0) {
        convertedOptions.excludeCredentials = webauthnOptions.excludeCredentials.map(cred => ({
            id: base64URLToArrayBuffer(cred.id),
            type: cred.type
        }));
    }

    console.log('Converted options:', convertedOptions);
    console.log('Starting WebAuthn registration...');

    // WebAuthn認証情報作成
    return navigator.credentials.create({
        publicKey: convertedOptions
    }).then(credential => {
        console.log('WebAuthn credential created:', credential);

        // サーバーに送信するデータを準備
        const credentialData = {
            id: credential.id,
            rawId: arrayBufferToBase64URL(credential.rawId),
            type: credential.type,
            response: {
                clientDataJSON: arrayBufferToBase64URL(credential.response.clientDataJSON),
                attestationObject: arrayBufferToBase64URL(credential.response.attestationObject)
            }
        };

        // CSRFトークンを取得
        const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

        // ニックネーム値を取得
        const nicknameField = document.getElementById('nickname');
        const nickname = nicknameField ? nicknameField.value : 'メインデバイス';

        // サーバーに登録データを送信
        return fetch('/webauthn_credentials', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({
                credential: credentialData,
                name: nickname
            })
        });
    }).then(response => {
        console.log('Registration response status:', response.status);

        // レスポンスのContent-Typeをチェック
        const contentType = response.headers.get('content-type');
        console.log('Response content-type:', contentType);

        if (contentType && contentType.includes('application/json')) {
            // JSONレスポンスの場合
            return response.json().then(data => {
                console.log('Registration response data:', data);

                if (data.success) {
                    // 成功時は認証管理ページにリダイレクト
                    window.location.href = data.redirect_url || '/webauthn_credentials';
                } else {
                    throw new Error(data.error || 'WebAuthn registration failed');
                }
            });
        } else {
            // HTMLレスポンスの場合（リダイレクト）
            if (response.ok) {
                // レスポンステキストを確認（デバッグ用）
                return response.text().then(html => {
                    console.log('HTML response received:', html.substring(0, 200) + '...');
                    // 成功として扱い、認証管理ページにリダイレクト
                    window.location.href = '/webauthn_credentials';
                });
            } else {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
        }
    }).catch(error => {
        console.error('WebAuthn registration failed:', error);

        // エラーメッセージを表示
        const errorDiv = document.getElementById('webauthn-error');
        if (errorDiv) {
            errorDiv.style.display = 'block';
            errorDiv.textContent = `登録に失敗しました: ${error.message}`;
        } else {
            alert(`WebAuthn登録に失敗しました: ${error.message}`);
        }

        throw error;
    });
}

// WebAuthn認証の開始
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

// グローバルに関数を公開
window.startWebAuthnRegistration = startWebAuthnRegistration;
window.startWebAuthnAuthentication = startWebAuthnAuthentication;