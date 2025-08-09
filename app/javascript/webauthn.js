
// Base64URL変換関数
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

// WebAuthn認証用の関数（修正版）
function startWebAuthnAuthentication(webauthnOptions) {
    console.log('WebAuthn authentication started');
    console.log('WebAuthn options received:', webauthnOptions);

    if (!navigator.credentials || !navigator.credentials.get) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    // WebAuthnオプションの構造をデバッグ
    console.log('Options structure analysis:');
    console.log('- challenge type:', typeof webauthnOptions.challenge);
    console.log('- allowCredentials type:', typeof webauthnOptions.allowCredentials);
    console.log('- allowCredentials content:', webauthnOptions.allowCredentials);

    // WebAuthnオプションの変換（改善版）
    const convertedOptions = {
        challenge: base64URLToArrayBuffer(webauthnOptions.challenge),
        timeout: webauthnOptions.timeout || 120000,
        rpId: webauthnOptions.rpId || webauthnOptions.rp_id,
        userVerification: webauthnOptions.userVerification || 'preferred'
    };

    // allowCredentialsの処理（改善版）
    if (webauthnOptions.allowCredentials && Array.isArray(webauthnOptions.allowCredentials)) {
        console.log('Processing allowCredentials array:', webauthnOptions.allowCredentials);

        convertedOptions.allowCredentials = webauthnOptions.allowCredentials.map((cred, index) => {
            console.log(`Processing credential ${index}:`, cred);
            console.log(`- cred.id type: ${typeof cred.id}`);
            console.log(`- cred.id value:`, cred.id);

            let credentialId;

            try {
                if (typeof cred.id === 'string') {
                    // Base64URL文字列の場合
                    credentialId = base64URLToArrayBuffer(cred.id);
                    console.log(`Converted string credential ID for ${index}`);
                } else if (cred.id instanceof ArrayBuffer) {
                    // 既にArrayBufferの場合
                    credentialId = cred.id;
                    console.log(`Using existing ArrayBuffer credential ID for ${index}`);
                } else if (Array.isArray(cred.id)) {
                    // 配列の場合（バイト配列）
                    credentialId = new Uint8Array(cred.id).buffer;
                    console.log(`Converted array credential ID for ${index}`);
                } else if (cred.id && typeof cred.id === 'object' && cred.id.buffer) {
                    // TypedArrayの場合
                    credentialId = cred.id.buffer;
                    console.log(`Converted TypedArray credential ID for ${index}`);
                } else if (typeof cred.id === 'object' && cred.id !== null) {
                    // オブジェクトの場合は文字列に変換してからBase64URL変換
                    const idString = JSON.stringify(cred.id);
                    console.log(`Converting object credential ID to string: ${idString}`);
                    credentialId = base64URLToArrayBuffer(btoa(idString).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, ''));
                    console.log(`Converted object credential ID for ${index}`);
                } else {
                    console.error(`Unknown credential ID type for ${index}:`, typeof cred.id, cred.id);
                    throw new Error(`Invalid credential ID format for credential ${index}`);
                }

                return {
                    id: credentialId,
                    type: cred.type || 'public-key'
                };
            } catch (error) {
                console.error(`Error processing credential ${index}:`, error);
                throw new Error(`Failed to process credential ${index}: ${error.message}`);
            }
        });
    } else if (webauthnOptions.allow && Array.isArray(webauthnOptions.allow)) {
        // Rails WebAuthn gemの'allow'プロパティを処理
        console.log('Processing allow array:', webauthnOptions.allow);

        convertedOptions.allowCredentials = webauthnOptions.allow.map((cred, index) => {
            console.log(`Processing allow credential ${index}:`, cred);

            let credentialId;
            try {
                if (typeof cred.id === 'string') {
                    credentialId = base64URLToArrayBuffer(cred.id);
                    console.log(`Converted string allow credential ID for ${index}`);
                } else if (Array.isArray(cred.id)) {
                    credentialId = new Uint8Array(cred.id).buffer;
                    console.log(`Converted array allow credential ID for ${index}`);
                } else if (typeof cred.id === 'object' && cred.id !== null) {
                    // オブジェクトの場合の処理
                    const idString = JSON.stringify(cred.id);
                    credentialId = base64URLToArrayBuffer(btoa(idString).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, ''));
                    console.log(`Converted object allow credential ID for ${index}`);
                } else {
                    credentialId = cred.id;
                    console.log(`Using existing allow credential ID for ${index}`);
                }

                return {
                    id: credentialId,
                    type: cred.type || 'public-key'
                };
            } catch (error) {
                console.error(`Error processing allow credential ${index}:`, error);
                throw new Error(`Failed to process allow credential ${index}: ${error.message}`);
            }
        });
    }

    console.log('Final converted authentication options:', {
        ...convertedOptions,
        challenge: '[ArrayBuffer]',
        allowCredentials: convertedOptions.allowCredentials?.map((cred, index) => ({
            ...cred,
            id: `[ArrayBuffer ${index}]`
        }))
    });

    // WebAuthn認証実行
    const authenticationPromise = navigator.credentials.get({
        publicKey: convertedOptions
    });

    // タイムアウト処理
    const timeoutPromise = new Promise((resolve, reject) => {
        setTimeout(() => {
            reject(new Error('WebAuthn authentication timeout'));
        }, (convertedOptions.timeout || 120000) + 5000);
    });

    return Promise.race([authenticationPromise, timeoutPromise])
        .then(credential => {
            console.log('WebAuthn authentication successful:', credential);

            if (!credential) {
                throw new Error('No credential returned from WebAuthn');
            }

            // サーバーに送信するデータを準備
            const credentialData = {
                id: credential.id,
                rawId: arrayBufferToBase64URL(credential.rawId),
                type: credential.type,
                response: {
                    clientDataJSON: arrayBufferToBase64URL(credential.response.clientDataJSON),
                    authenticatorData: arrayBufferToBase64URL(credential.response.authenticatorData),
                    signature: arrayBufferToBase64URL(credential.response.signature),
                    userHandle: credential.response.userHandle ? arrayBufferToBase64URL(credential.response.userHandle) : null
                }
            };

            console.log('Sending credential data to server:', credentialData);

            // CSRFトークンを取得
            const csrfToken = document.querySelector('meta[name="csrf-token"]');
            if (!csrfToken) {
                throw new Error('CSRF token not found');
            }

            // サーバーに認証データを送信
            return fetch('/webauthn_authentications', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-Token': csrfToken.getAttribute('content')
                },
                body: JSON.stringify({
                    credential: credentialData
                })
            });
        })
        .then(response => {
            console.log('Authentication response status:', response.status);

            const contentType = response.headers.get('content-type');
            console.log('Response content-type:', contentType);

            if (response.ok) {
                if (response.redirected) {
                    console.log('Response was redirected to:', response.url);
                    window.location.href = response.url;
                } else if (contentType && contentType.includes('application/json')) {
                    return response.json().then(data => {
                        console.log('Authentication response data:', data);
                        if (data.success) {
                            window.location.href = data.redirect_url || '/';
                        } else {
                            throw new Error(data.error || 'Authentication failed');
                        }
                    });
                } else {
                    console.log('HTML response received, assuming success');
                    window.location.href = '/';
                }
            } else {
                if (contentType && contentType.includes('application/json')) {
                    return response.json().then(data => {
                        throw new Error(data.error || `HTTP error! status: ${response.status}`);
                    });
                } else {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
            }
        })
        .catch(error => {
            console.error('WebAuthn authentication failed:', error);
            throw error;
        });
}

// WebAuthn登録用の関数（既存のまま）
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
            authenticatorAttachment: 'platform',
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

    return navigator.credentials.create({
        publicKey: convertedOptions
    }).then(credential => {
        console.log('WebAuthn credential created:', credential);

        const credentialData = {
            id: credential.id,
            rawId: arrayBufferToBase64URL(credential.rawId),
            type: credential.type,
            response: {
                clientDataJSON: arrayBufferToBase64URL(credential.response.clientDataJSON),
                attestationObject: arrayBufferToBase64URL(credential.response.attestationObject)
            }
        };

        const csrfTokenElement = document.querySelector('meta[name="csrf-token"]');
        if (!csrfTokenElement) {
            throw new Error('CSRF token not found');
        }
        const csrfToken = csrfTokenElement.getAttribute('content');

        const nicknameField = document.getElementById('nickname');
        const nickname = nicknameField ? nicknameField.value : 'メインデバイス';

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

        const contentType = response.headers.get('content-type');
        console.log('Response content-type:', contentType);

        if (contentType && contentType.includes('application/json')) {
            return response.json().then(data => {
                console.log('Registration response data:', data);

                if (data.success) {
                    window.location.href = data.redirect_url || '/webauthn_credentials';
                } else {
                    throw new Error(data.error || 'WebAuthn registration failed');
                }
            });
        } else {
            if (response.ok) {
                return response.text().then(html => {
                    console.log('HTML response received:', html.substring(0, 200) + '...');
                    window.location.href = '/webauthn_credentials';
                });
            } else {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
        }
    }).catch(error => {
        console.error('WebAuthn registration failed:', error);

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

// 初期化チェック関数
function initializeWebAuthn() {
    const webauthnEmail = document.getElementById('webauthn-email');

    if (!webauthnEmail) {
        console.log('WebAuthn elements not found, skipping WebAuthn initialization');
        return;
    }

    console.log('WebAuthn elements found, initializing...');
}

// グローバル関数として定義
window.startWebAuthnAuthentication = startWebAuthnAuthentication;
window.startWebAuthnRegistration = startWebAuthnRegistration;
window.initializeWebAuthn = initializeWebAuthn;

// DOMContentLoaded時に初期化を実行
document.addEventListener('DOMContentLoaded', function() {
    console.log('WebAuthn module loaded');
    window.webAuthnModuleLoaded = true;
});

// ES6モジュールとしてもエクスポート
export {
    startWebAuthnAuthentication,
    startWebAuthnRegistration,
    initializeWebAuthn,
    base64URLToArrayBuffer,
    arrayBufferToBase64URL
};