#!/bin/bash
yum update -y
yum install -y docker

# Dockerサービスの開始と自動起動設定
systemctl start docker
systemctl enable docker

# ec2-userをdockerグループに追加
usermod -a -G docker ec2-user

# PC名ベースのユーザー設定（1ユーザーのみ）
%{ for key in public_keys ~}
# ${key.name} ユーザー用の設定
if ! id "${key.name}" &>/dev/null; then
    useradd -m -s /bin/bash ${key.name}
    usermod -a -G docker ${key.name}
    usermod -a -G wheel ${key.name}
fi

# SSH公開鍵の設定
mkdir -p /home/${key.name}/.ssh
echo "${key.public_key}" >> /home/${key.name}/.ssh/authorized_keys
chown -R ${key.name}:${key.name} /home/${key.name}/.ssh
chmod 700 /home/${key.name}/.ssh
chmod 600 /home/${key.name}/.ssh/authorized_keys

%{ endfor ~}

# sudoers設定（wheelグループにsudo権限）
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel-nopasswd

# Docker Composeのインストール
curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose