#!/bin/bash

echo "🔍 Checking what's running on port 8080..."
netstat -tulpn | grep :8080 || lsof -i :8080 || echo "No process found on port 8080"

echo "🛑 Stopping all running containers..."
docker stop $(docker ps -aq) 2>/dev/null || echo "No containers to stop"

echo "🗑️ Removing stopped containers..."
docker rm $(docker ps -aq) 2>/dev/null || echo "No containers to remove"

echo "📋 Current Docker status:"
docker ps -a

echo "🔌 Checking port availability:"
ss -tulpn | grep :8080 || echo "Port 8080 is now free"

echo "✅ Cleanup complete!"