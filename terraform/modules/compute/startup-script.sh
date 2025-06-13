#!/bin/bash
# Update system
sudo apt-get update
sudo apt-get install -y docker.io docker-compose nginx

# Start services
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Create environment file for microservices
cat << EOF > /home/debian/.env
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
ENVIRONMENT=${environment}
EOF

# Setup basic nginx configuration
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Setup completed successfully for environment: ${environment}" > /var/log/startup-script.log
