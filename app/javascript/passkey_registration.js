document.addEventListener('DOMContentLoaded', function() {
    const registerButton = document.getElementById('register-passkey');
    const statusDiv = document.getElementById('passkey-status');

    if (registerButton) {
        registerButton.addEventListener('click', async function() {
            console.log('Passkey registration button clicked');
            
            // UI更新
            statusDiv.style.display = 'block';
            registerButton.disabled = true;

            try {
                // WebAuthnサポートチェック
                if (!navigator.credentials || !navigator.credentials.create) {
                    throw new Error('このブラウザはWebAuthn/パスキーをサポートしていません');
                }

                console.log('Fetching registration options...');
                
                // サーバーから登録オプションを取得
                const response = await fetch('/users/passkeys/new.json', {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                    }
                });

                console.log('Options response status:', response.status);

                if (!response.ok) {
                    throw new Error(`サーバーエラー: ${response.status}`);
                }

                const options = await response.json();
                console.log('Received options:', options);

                // パスキー登録オプションの変換
                const credentialCreationOptions = {
                    publicKey: {
                        challenge: Uint8Array.from(atob(options.publicKey.challenge.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0)),
                        rp: options.publicKey.rp,
                        user: {
                            id: Uint8Array.from(atob(options.publicKey.user.id.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0)),
                            name: options.publicKey.user.name,
                            displayName: options.publicKey.user.displayName
                        },
                        pubKeyCredParams: options.publicKey.pubKeyCredParams,
                        authenticatorSelection: options.publicKey.authenticatorSelection,
                        timeout: options.publicKey.timeout,
                        attestation: options.publicKey.attestation
                    }
                };

                console.log('Creating credential with options:', credentialCreationOptions);

                // WebAuthn API を使用してパスキーを作成
                const credential = await navigator.credentials.create(credentialCreationOptions);
                
                console.log('Credential created:', credential);

                if (!credential) {
                    throw new Error('認証情報の作成に失敗しました');
                }

                // サーバーに送信するためのデータを準備
                const credentialData = {
                    id: credential.id,
                    rawId: Array.from(new Uint8Array(credential.rawId)),
                    response: {
                        attestationObject: Array.from(new Uint8Array(credential.response.attestationObject)),
                        clientDataJSON: Array.from(new Uint8Array(credential.response.clientDataJSON))
                    },
                    type: credential.type
                };

                console.log('Sending credential data to server...');

                // サーバーに認証情報を送信
                const formData = new FormData();
                formData.append('credential', JSON.stringify(credentialData));

                const submitResponse = await fetch('/users/passkeys', {
                    method: 'POST',
                    body: formData,
                    headers: {
                        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
                    }
                });

                console.log('Submit response status:', submitResponse.status);

                if (submitResponse.ok) {
                    console.log('Registration successful, redirecting...');
                    window.location.href = '/users/passkeys';
                } else {
                    const errorText = await submitResponse.text();
                    console.error('Submit response error:', errorText);
                    throw new Error('登録に失敗しました');
                }

            } catch (error) {
                console.error('Passkey registration failed:', error);
                
                let errorMessage = 'パスキーの登録に失敗しました';
                
                if (error.name === 'NotAllowedError') {
                    errorMessage = 'パスキー登録がキャンセルされました';
                } else if (error.name === 'NotSupportedError') {
                    errorMessage = 'このデバイスはパスキーをサポートしていません';
                } else if (error.name === 'SecurityError') {
                    errorMessage = 'セキュリティエラーが発生しました';
                } else if (error.name === 'AbortError') {
                    errorMessage = 'パスキー登録がタイムアウトしました';
                } else if (error.message) {
                    errorMessage = error.message;
                }
                
                // エラー表示
                statusDiv.innerHTML = `
                    <div class="alert alert-danger">
                        <i class="fas fa-exclamation-triangle me-2"></i>${errorMessage}
                    </div>
                `;
                
                registerButton.disabled = false;
            }
        });
    }
});