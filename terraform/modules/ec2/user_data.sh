#!/bin/bash
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

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

# Create users with their SSH keys
%{ for user in public_keys ~}
# Create user: ${user.name}
useradd -m -s /bin/bash ${user.name}
usermod -aG wheel ${user.name}
usermod -aG docker ${user.name}

# Set up SSH key for ${user.name}
mkdir -p /home/${user.name}/.ssh
echo "${user.public_key}" > /home/${user.name}/.ssh/authorized_keys
chmod 700 /home/${user.name}/.ssh
chmod 600 /home/${user.name}/.ssh/authorized_keys
chown -R ${user.name}:${user.name} /home/${user.name}/.ssh

# Allow sudo without password
echo "${user.name} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${user.name}
%{ endfor ~}

# Set up firewall rules
yum install -y firewalld
systemctl start firewalld
systemctl enable firewalld

# Allow custom SSH port and web ports
firewall-cmd --permanent --add-port=47583/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

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