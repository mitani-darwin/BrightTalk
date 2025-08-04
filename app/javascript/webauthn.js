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

// WebAuthn認証用の関数（Safari対応版）
function startWebAuthnAuthentication(webauthnOptions) {
    console.log('WebAuthn authentication started');
    console.log('WebAuthn options:', webauthnOptions);

    if (!navigator.credentials || !navigator.credentials.get) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    // WebAuthnオプションの変換（Safari対応版）
    const convertedOptions = {
        challenge: base64URLToArrayBuffer(webauthnOptions.challenge),
        timeout: webauthnOptions.timeout || 60000,
        rpId: webauthnOptions.rpId,
        userVerification: webauthnOptions.userVerification || 'preferred' // Safariで'required'が問題を起こす場合があるため
    };

    // allowCredentialsの処理を修正
    if (webauthnOptions.allowCredentials && Array.isArray(webauthnOptions.allowCredentials)) {
        convertedOptions.allowCredentials = webauthnOptions.allowCredentials.map(cred => {
            console.log('Processing credential:', cred);

            // cred.idの構造をチェック
            let credentialId;

            if (typeof cred.id === 'string') {
                // Base64URL文字列の場合
                credentialId = base64URLToArrayBuffer(cred.id);
                console.log('Converted string credential ID');
            } else if (cred.id && typeof cred.id === 'object' && typeof cred.id.id === 'string') {
                // ネストされたオブジェクトの場合 {id: "...", type: "public-key"}
                credentialId = base64URLToArrayBuffer(cred.id.id);
                console.log('Converted nested object credential ID');
            } else if (cred.id instanceof ArrayBuffer) {
                // 既にArrayBufferの場合
                credentialId = cred.id;
                console.log('Using existing ArrayBuffer credential ID');
            } else if (cred.id && cred.id.buffer) {
                // TypedArrayの場合
                credentialId = cred.id.buffer;
                console.log('Converted TypedArray credential ID');
            } else {
                console.error('Unknown credential ID type:', typeof cred.id, cred.id);
                throw new Error('Invalid credential ID format');
            }

            return {
                id: credentialId,
                type: cred.type || 'public-key'
            };
        });
    }

    console.log('Converted authentication options:', convertedOptions);

    // Safariでのタイムアウト対策
    const authenticationPromise = navigator.credentials.get({
        publicKey: convertedOptions
    });

    // 追加のタイムアウト処理
    const timeoutPromise = new Promise((resolve, reject) => {
        setTimeout(() => {
            reject(new Error('WebAuthn authentication timeout'));
        }, (convertedOptions.timeout || 60000) + 5000); // 少し余裕を持たせる
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
            console.log('Authentication response headers:', response.headers);

            // レスポンスの詳細をログ出力
            const contentType = response.headers.get('content-type');
            console.log('Response content-type:', contentType);

            if (response.ok) {
                // Safariでのリダイレクト処理を改善
                if (response.redirected) {
                    console.log('Response was redirected to:', response.url);
                    window.location.href = response.url;
                    return;
                }

                // JSONレスポンスの場合
                if (contentType && contentType.includes('application/json')) {
                    return response.json().then(data => {
                        console.log('JSON response data:', data);
                        if (data.redirect_url) {
                            window.location.href = data.redirect_url;
                        } else {
                            window.location.href = '/';
                        }
                    });
                }

                // HTMLレスポンスの場合（通常のリダイレクト）
                window.location.href = '/';
            } else {
                // エラーレスポンスの処理
                if (contentType && contentType.includes('application/json')) {
                    return response.json().then(data => {
                        throw new Error(data.error || 'WebAuthn authentication failed');
                    });
                } else {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
            }
        })
        .catch(error => {
            console.error('WebAuthn authentication failed:', error);

            // Safariでの特定エラーメッセージを判定
            let errorMessage = error.message;
            if (error.name === 'NotSupportedError') {
                errorMessage = 'このデバイスではWebAuthn認証がサポートされていません。';
            } else if (error.name === 'SecurityError') {
                errorMessage = 'セキュリティエラーが発生しました。ページを再読み込みしてお試しください。';
            } else if (error.name === 'AbortError') {
                errorMessage = '認証がキャンセルされました。';
            } else if (error.name === 'NotAllowedError') {
                errorMessage = '認証が拒否されました。Touch IDまたはFace IDを確認してください。';
            } else if (error.message.includes('timeout')) {
                errorMessage = '認証がタイムアウトしました。再度お試しください。';
            }

            throw new Error(errorMessage);
        });
}

// Base64URL変換関数（エラーハンドリングを強化）
function base64URLToArrayBuffer(base64url) {
    if (!base64url || typeof base64url !== 'string') {
        console.error('Invalid base64url input:', base64url);
        throw new Error('Invalid base64URL string');
    }

    try {
        // Base64URLをBase64に変換
        let base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');

        // パディングを追加
        while (base64.length % 4) {
            base64 += '=';
        }

        // Base64をArrayBufferに変換
        const binaryString = window.atob(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    } catch (error) {
        console.error('Failed to decode base64url:', base64url, error);
        throw new Error('Failed to decode base64URL string: ' + error.message);
    }
}

function arrayBufferToBase64URL(buffer) {
    if (!buffer) {
        throw new Error('Buffer is required');
    }

    try {
        // ArrayBufferをUint8Arrayに変換
        const bytes = new Uint8Array(buffer);

        // バイナリ文字列に変換
        let binaryString = '';
        for (let i = 0; i < bytes.byteLength; i++) {
            binaryString += String.fromCharCode(bytes[i]);
        }

        // Base64に変換してからBase64URLに変換
        return window.btoa(binaryString)
            .replace(/\+/g, '-')
            .replace(/\//g, '_')
            .replace(/=/g, '');
    } catch (error) {
        console.error('Failed to encode to base64url:', error);
        throw new Error('Failed to encode to base64URL: ' + error.message);
    }
}

// WebAuthn認証処理の改善版
export class WebAuthnHandler {
    constructor() {
        this.abortController = null;
        this.isAuthenticating = false;
    }

    // 既存の認証プロセスを中断
    abortCurrentAuthentication() {
        if (this.abortController) {
            this.abortController.abort();
            this.abortController = null;
        }
        this.isAuthenticating = false;
    }

    async authenticate(options, onSuccess, onError) {
        // 既存の認証プロセスがある場合は中断
        this.abortCurrentAuthentication();

        // 重複認証防止
        if (this.isAuthenticating) {
            console.log('WebAuthn authentication already in progress');
            return;
        }

        this.isAuthenticating = true;
        this.abortController = new AbortController();

        try {
            // タイムアウト設定（60秒）
            const timeoutId = setTimeout(() => {
                this.abortController.abort();
            }, 60000);

            const credential = await navigator.credentials.get({
                publicKey: {
                    ...options,
                    timeout: 60000 // 60秒のタイムアウト
                },
                signal: this.abortController.signal
            });

            clearTimeout(timeoutId);
            this.isAuthenticating = false;

            if (onSuccess) {
                onSuccess(credential);
            }

        } catch (error) {
            this.isAuthenticating = false;

            // エラーの種類に応じた処理
            if (error.name === 'AbortError') {
                console.log('WebAuthn認証がキャンセルまたはタイムアウトしました');
                if (onError) {
                    onError('認証がキャンセルされました');
                }
            } else if (error.name === 'NotAllowedError') {
                console.log('ユーザーが認証をキャンセルしました');
                if (onError) {
                    onError('認証がキャンセルされました');
                }
            } else if (error.name === 'InvalidStateError') {
                console.log('認証デバイスが利用できません');
                if (onError) {
                    onError('認証デバイスが利用できません');
                }
            } else {
                console.error('WebAuthn認証エラー:', error);
                if (onError) {
                    onError('認証に失敗しました: ' + error.message);
                }
            }
        }
    }
}

// グローバルインスタンス
window.startWebAuthnRegistration = startWebAuthnRegistration;
window.startWebAuthnAuthentication = startWebAuthnAuthentication;
window.webauthnHandler = new WebAuthnHandler();
