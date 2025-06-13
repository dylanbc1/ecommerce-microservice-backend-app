#!/bin/bash

# Update system
apt-get update
apt-get install -y docker.io docker-compose git

# Start Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Create app directory
mkdir -p /opt/ecommerce-app
cd /opt/ecommerce-app

# Clone or copy your application code here
# git clone https://github.com/your-repo/ecommerce-microservice-backend-app.git .

# Create environment file
cat > .env << EOF
NODE_ENV=production
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_PORT=5432
PORT=3000
EOF

# Set permissions
chown -R ubuntu:ubuntu /opt/ecommerce-app
