#!/bin/bash

echo "🎬 NordVPN Media Stack Setup"
echo "============================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Please log out and back in, then run this script again"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found. Installing..."
    sudo apt-get update
    sudo apt-get install docker-compose-plugin -y
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p ./media/{downloads,movies,tv}
mkdir -p ./config/{qbittorrent,prowlarr,sonarr,radarr,jellyseerr,jellyfin}

# Set permissions
echo "🔐 Setting permissions..."
sudo chown -R $USER:$USER ./media ./config

# Get local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Your server IP: $LOCAL_IP"

# Check for .env file
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "📝 Please edit .env file with your NordVPN credentials"
        echo "   Get them from: https://my.nordaccount.com/dashboard/nordvpn/"
        echo "   Then run: docker-compose up -d"
        exit 0
    else
        echo "❌ .env.example not found. Please create .env file manually"
        exit 1
    fi
fi

# Start services
echo "🚀 Starting services..."
docker-compose up -d

echo "✅ Setup complete!"
echo ""
echo "🎯 Access your services at:"
echo "   Request Movies/Shows: http://$LOCAL_IP:5055"
echo "   Watch Content:        http://$LOCAL_IP:8096"
echo "   System Admin:         http://$LOCAL_IP:9000"
echo ""
echo "⚙️  One-time configuration needed:"
echo "   Download Client:      http://$LOCAL_IP:8080"
echo "   TV Manager:          http://$LOCAL_IP:8989"
echo "   Movie Manager:       http://$LOCAL_IP:7878"
echo "   Indexer Manager:     http://$LOCAL_IP:9117"