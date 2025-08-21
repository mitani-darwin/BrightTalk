
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

// Passkey認証用の関数
function startPasskeyAuthentication(passkeyOptions) {
    console.log('Passkey authentication started');
    console.log('Passkey options received:', passkeyOptions);

    if (!navigator.credentials || !navigator.credentials.get) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    // Passkeyオプションの変換
    const convertedOptions = {
        challenge: base64URLToArrayBuffer(passkeyOptions.challenge),
        timeout: passkeyOptions.timeout || 300000,
        rpId: passkeyOptions.rpId,
        userVerification: passkeyOptions.userVerification || 'required'
    };

    // allowCredentialsの処理
    if (passkeyOptions.allowCredentials && Array.isArray(passkeyOptions.allowCredentials)) {
        console.log('Processing allowCredentials array:', passkeyOptions.allowCredentials);

        convertedOptions.allowCredentials = passkeyOptions.allowCredentials.map((cred, index) => {
            console.log(`Processing credential ${index}:`, cred);

            let credentialId;
            try {
                if (typeof cred.id === 'string') {
                    credentialId = base64URLToArrayBuffer(cred.id);
                    console.log(`Converted string credential ID for ${index}`);
                } else if (Array.isArray(cred.id)) {
                    credentialId = new Uint8Array(cred.id).buffer;
                    console.log(`Converted array credential ID for ${index}`);
                } else {
                    credentialId = cred.id;
                    console.log(`Using existing credential ID for ${index}`);
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
    }

    console.log('Final converted authentication options:', {
        ...convertedOptions,
        challenge: '[ArrayBuffer]',
        allowCredentials: convertedOptions.allowCredentials?.map((cred, index) => ({
            ...cred,
            id: `[ArrayBuffer ${index}]`
        }))
    });

    // Passkey認証実行
    return navigator.credentials.get({
        publicKey: convertedOptions
    }).then(credential => {
        console.log('Passkey authentication successful:', credential);

        if (!credential) {
            throw new Error('No credential returned from Passkey');
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
        return fetch('/passkey_authentications', {
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
    }).then(response => {
        console.log('Authentication response status:', response.status);

        const contentType = response.headers.get('content-type');
        console.log('Response content-type:', contentType);

        if (response.ok) {
            if (contentType && contentType.includes('application/json')) {
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
    }).catch(error => {
        console.error('Passkey authentication failed:', error);
        throw error;
    });
}

// Passkey登録用の関数
function startPasskeyRegistration(passkeyOptions, label) {
    console.log('Passkey registration started');

    if (!navigator.credentials || !navigator.credentials.create) {
        throw new Error('WebAuthn is not supported by this browser');
    }

    console.log('Passkey options:', passkeyOptions);

    // WebAuthnオプションの変換
    const convertedOptions = {
        challenge: base64URLToArrayBuffer(passkeyOptions.challenge),
        rp: passkeyOptions.rp,
        user: {
            id: base64URLToArrayBuffer(passkeyOptions.user.id),
            name: passkeyOptions.user.name,
            displayName: passkeyOptions.user.displayName
        },
        pubKeyCredParams: passkeyOptions.pubKeyCredParams,
        timeout: passkeyOptions.timeout,
        attestation: passkeyOptions.attestation || 'direct',
        authenticatorSelection: passkeyOptions.authenticatorSelection
    };

    // excludeCredentialsがある場合は変換
    if (passkeyOptions.excludeCredentials && passkeyOptions.excludeCredentials.length > 0) {
        convertedOptions.excludeCredentials = passkeyOptions.excludeCredentials.map(cred => ({
            id: base64URLToArrayBuffer(cred.id),
            type: cred.type
        }));
    }

    console.log('Converted options:', convertedOptions);
    console.log('Starting Passkey registration...');

    return navigator.credentials.create({
        publicKey: convertedOptions
    }).then(credential => {
        console.log('Passkey credential created:', credential);

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

        return fetch('/passkey_registrations/verify_passkey', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-Token': csrfToken
            },
            body: JSON.stringify({
                credential: credentialData,
                label: label
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
                    // 仮登録完了の場合はリダイレクトしない
                    if (data.show_confirmation_notice) {
                        return data;
                    } else {
                        window.location.href = data.redirect_url || '/';
                    }
                } else {
                    throw new Error(data.error || 'Passkey registration failed');
                }
            });
        } else {
            if (response.ok) {
                return response.text().then(html => {
                    console.log('HTML response received:', html.substring(0, 200) + '...');
                    window.location.href = '/';
                });
            } else {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
        }
    }).catch(error => {
        console.error('Passkey registration failed:', error);
        throw error;
    });
}

// グローバル関数として定義
window.startPasskeyAuthentication = startPasskeyAuthentication;
window.startPasskeyRegistration = startPasskeyRegistration;

// DOMContentLoaded時に初期化を実行
document.addEventListener('DOMContentLoaded', function() {
    console.log('Passkey module loaded');
    window.passkeyModuleLoaded = true;
});