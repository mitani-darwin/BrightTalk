// Turbo対応のため、turbo:loadイベントも監視
document.addEventListener('DOMContentLoaded', initializeWebAuthn);
document.addEventListener('turbo:load', initializeWebAuthn);

function initializeWebAuthn() {
    const loginButton = document.getElementById('webauthn-login-btn');
    const emailInput = document.getElementById('email-input');

    if (!loginButton || !emailInput) return;

    // 既存のイベントリスナーを削除してから追加（重複防止）
    loginButton.removeEventListener('click', handleLogin);
    loginButton.addEventListener('click', handleLogin);
}

async function handleLogin(event) {
    event.preventDefault();

    const loginButton = event.target;
    const emailInput = document.getElementById('email-input');
    const authStatus = document.getElementById('auth-status');
    const email = emailInput.value.trim();

    if (!email) {
        alert('メールアドレスを入力してください。');
        return;
    }

    try {
        loginButton.disabled = true;
        loginButton.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>認証準備中...';

        authStatus.className = 'alert alert-info';
        authStatus.innerHTML = '<i class="bi bi-info-circle me-2"></i>WebAuthn認証の準備をしています...';
        authStatus.classList.remove('d-none');

        // Step 1: サーバーからWebAuthnオプションを取得
        const checkPath = document.getElementById('webauthn-check-path').textContent;
        const response = await fetch(`${checkPath}?email=${encodeURIComponent(email)}`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || '認証の準備に失敗しました。');
        }

        const data = await response.json();

        if (!data.webauthn_options) {
            throw new Error('WebAuthn認証が設定されていないか、アカウントが存在しません。');
        }

        // Step 2: WebAuthn認証を実行
        loginButton.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>認証中...';
        authStatus.innerHTML = '<i class="bi bi-shield-check me-2"></i>認証デバイスを使用してください...';

        const options = data.webauthn_options;
        console.log('WebAuthn options:', options);

        // Base64URLエンコードされた値をArrayBufferに変換
        options.challenge = base64URLToArrayBuffer(options.challenge);

        if (options.allowCredentials) {
            options.allowCredentials = options.allowCredentials.map(cred => ({
                ...cred,
                id: base64URLToArrayBuffer(cred.id)
            }));
        }

        console.log('Calling navigator.credentials.get...');
        const credential = await navigator.credentials.get({
            publicKey: options
        });

        console.log('WebAuthn authentication successful:', credential);

        // Step 3: サーバーに認証結果を送信
        authStatus.innerHTML = '<i class="bi bi-check-circle me-2"></i>認証を確認しています...';

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

        const formData = new FormData();
        formData.append('credential[id]', credentialData.id);
        formData.append('credential[rawId]', credentialData.rawId);
        formData.append('credential[type]', credentialData.type);
        formData.append('credential[response][clientDataJSON]', credentialData.response.clientDataJSON);
        formData.append('credential[response][authenticatorData]', credentialData.response.authenticatorData);
        formData.append('credential[response][signature]', credentialData.response.signature);
        if (credentialData.response.userHandle) {
            formData.append('credential[response][userHandle]', credentialData.response.userHandle);
        }
        formData.append('authenticity_token', document.querySelector('meta[name="csrf-token"]').content);

        const authPath = document.getElementById('webauthn-auth-path').textContent;
        console.log('Sending authentication data to:', authPath);

        const authResponse = await fetch(authPath, {
            method: 'POST',
            body: formData
        });

        if (authResponse.ok) {
            authStatus.className = 'alert alert-success';
            authStatus.innerHTML = '<i class="bi bi-check-circle me-2"></i>認証成功！リダイレクトしています...';

            const rootPath = document.getElementById('root-path').textContent;
            console.log('Authentication successful, redirecting to:', rootPath);
            setTimeout(() => {
                window.location.href = rootPath;
            }, 1000);
        } else {
            const errorText = await authResponse.text();
            console.error('Server response:', errorText);
            throw new Error('認証の確認に失敗しました。');
        }
    } catch (error) {
        console.error('WebAuthn authentication failed:', error);

        authStatus.className = 'alert alert-danger';
        authStatus.innerHTML = `<i class="bi bi-exclamation-triangle me-2"></i>認証に失敗しました: ${error.message}`;

        loginButton.disabled = false;
        loginButton.innerHTML = '<i class="bi bi-shield-check me-2"></i>WebAuthn認証';
    }
}

function base64URLToArrayBuffer(base64URL) {
    const base64 = base64URL.replace(/-/g, '+').replace(/_/g, '/');
    const padding = base64.length % 4;
    const padded = padding ? base64 + '='.repeat(4 - padding) : base64;
    const binaryString = atob(padded);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
}

function arrayBufferToBase64URL(arrayBuffer) {
    const bytes = new Uint8Array(arrayBuffer);
    let binaryString = '';
    for (let i = 0; i < bytes.length; i++) {
        binaryString += String.fromCharCode(bytes[i]);
    }
    return btoa(binaryString).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}