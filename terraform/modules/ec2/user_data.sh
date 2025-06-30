#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/${project_name}
chown ec2-user:ec2-user /opt/${project_name}

# Basic web server for health check
cat > /tmp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - ${environment}</title>
</head>
<body>
    <h1>${project_name} - ${environment}</h1>
    <p>Server is running</p>
</body>
</html>
EOF

# Start simple HTTP server for health check
nohup python3 -m http.server 80 --directory /tmp > /var/log/simple-server.log 2>&1 &