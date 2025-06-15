document.addEventListener('DOMContentLoaded', function() {
    const authenticateButton = document.getElementById('authenticate-webauthn');

    if (!authenticateButton) return;

    authenticateButton.addEventListener('click', async function() {
        try {
            authenticateButton.disabled = true;
            authenticateButton.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>認証中...';

            const optionsElement = document.getElementById('webauthn-options');
            if (!optionsElement) {
                throw new Error('WebAuthn options not found');
            }

            const options = JSON.parse(optionsElement.textContent);

            // Base64URLエンコードされた値をArrayBufferに変換
            options.challenge = base64URLToArrayBuffer(options.challenge);

            if (options.allowCredentials) {
                options.allowCredentials = options.allowCredentials.map(cred => ({
                    ...cred,
                    id: base64URLToArrayBuffer(cred.id)
                }));
            }

            const credential = await navigator.credentials.get({
                publicKey: options
            });

            // レスポンスをサーバーに送信可能な形式に変換
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

            // サーバーに送信
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
            const response = await fetch(authPath, {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                const rootPath = document.getElementById('root-path').textContent;
                window.location.href = rootPath;
            } else {
                throw new Error('Authentication failed');
            }
        } catch (error) {
            console.error('WebAuthn authentication failed:', error);
            alert('認証に失敗しました。もう一度お試しください。');
            authenticateButton.disabled = false;
            authenticateButton.innerHTML = '<i class="bi bi-shield-check me-2"></i>認証を開始';
        }
    });

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
});