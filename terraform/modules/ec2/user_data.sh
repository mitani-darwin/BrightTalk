#!/bin/bash
yum update -y

# Fix locale issues - 日本のロケール設定
echo 'export LC_ALL=ja_JP.UTF-8' >> /etc/environment
echo 'export LANG=ja_JP.UTF-8' >> /etc/environment
echo 'export LANGUAGE=ja_JP.UTF-8' >> /etc/environment

# Install Japanese locale packages
yum install -y glibc-langpack-ja glibc-locale-source

# Generate Japanese locale
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8

# Set system locale to Japanese
localectl set-locale LANG=ja_JP.UTF-8

# Configure locale for ec2-user
echo 'export LC_ALL=ja_JP.UTF-8' >> /home/ec2-user/.bashrc
echo 'export LANG=ja_JP.UTF-8' >> /home/ec2-user/.bashrc
echo 'export LANGUAGE=ja_JP.UTF-8' >> /home/ec2-user/.bashrc

# Set timezone to Japan
timedatectl set-timezone Asia/Tokyo

# Disable and remove any firewall services
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
yum remove -y firewalld iptables-services 2>/dev/null || true

# Install SSM Agent
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Wait for Docker to be fully ready
sleep 10

# Change SSH port to 47583 for maximum security obfuscation
sed -i 's/#Port 22/Port 47583/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 47583/' /etc/ssh/sshd_config

# Additional SSH security hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Configure ec2-user for Docker and SSH keys
%{ for user in public_keys ~}
# Add SSH key for ec2-user
mkdir -p /home/ec2-user/.ssh
echo "${user.public_key}" >> /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user/.ssh
chmod 600 /home/ec2-user/.ssh/authorized_keys
chown -R ec2-user:ec2-user /home/ec2-user/.ssh
%{ endfor ~}

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Docker socket permissions (永続化)
chmod 666 /var/run/docker.sock
chown root:docker /var/run/docker.sock

# Install additional tools
yum install -y git curl wget htop fail2ban

# Configure fail2ban for SSH protection
systemctl enable fail2ban
systemctl start fail2ban

# Create fail2ban SSH jail configuration
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 47583
logpath = /var/log/secure
backend = systemd
EOF

systemctl restart fail2ban

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure Docker daemon for optimal networking
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "userland-proxy": false,
  "live-restore": true
}
EOF

# Restart Docker with new configuration
systemctl restart docker

# Create a startup script to fix docker permissions on boot
cat > /etc/systemd/system/docker-permissions.service << EOF
[Unit]
Description=Fix Docker permissions
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'chmod 666 /var/run/docker.sock && chown root:docker /var/run/docker.sock'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable docker-permissions.service
systemctl start docker-permissions.service

echo "User data script completed successfully - 日本のロケール設定完了、ファイアーウォール無効化完了"

# Swapfile 4GB 作成
fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 永続化
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# swappiness 調整（オプション）
sysctl vm.swappiness=10
echo 'vm.swappiness=10' >> /etc/sysctl.conf
