# Complete NordVPN Media Stack Repository

## README.md
```markdown
# NordVPN Media Stack

**Stop paying for multiple streaming subscriptions. Build your own Netflix in 30 minutes.**

One-command setup for a complete automated media server with torrent privacy protection.

## What You Get

- **Request Interface**: Ask for any movie/show through a web interface
- **Automatic Downloads**: System finds and downloads content automatically  
- **Personal Netflix**: Stream everything through your own media server
- **Complete Privacy**: All torrent traffic routed through NordVPN

## Requirements

**Hardware**: Any laptop, desktop, or server with:
- 4GB+ RAM  
- 500GB+ storage
- Ethernet connection (WiFi will be slow)

**Software**: Linux with Docker
- Don't have Linux? → [Ubuntu Server Setup Guide](https://ubuntu.com/server/docs/installation)  
- Already have Ubuntu/Debian/etc? → You're ready to go

**Subscriptions**: 
- NordVPN account ([get service credentials here](https://my.nordaccount.com/dashboard/nordvpn/manual-setup/))

## Quick Start

### 1. Find Your Server IP
```bash
# Get your server's local IP address
hostname -I | awk '{print $1}'
# Example output: 192.168.0.167
```

### 2. Install Docker (if not installed)
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```
**Log out and back in after this step**

### 3. Create Setup Directory
```bash
mkdir -p ~/mediastack && cd ~/mediastack
mkdir -p ./media/{downloads,movies,tv}
```

### 4. Download Configuration
```bash
# Option A: Use automated setup script (recommended)
curl -O https://raw.githubusercontent.com/Harmanhrm/NordVpn-Personal-Media-Server/main/setup.sh
chmod +x setup.sh
./setup.sh

# Option B: Manual setup
curl -O https://raw.githubusercontent.com/Harmanhrm/NordVpn-Personal-Media-Server/main/docker-compose.yml
```

### 5. Add Your NordVPN Credentials

**Option A: Using .env file (recommended)**
```bash
# Download environment template
curl -O https://raw.githubusercontent.com/Harmanhrm/NordVpn-Personal-Media-Server/main/.env.example
cp .env.example .env
nano .env
```

**Option B: Direct editing**
```bash
# Edit the docker-compose.yml file directly
nano docker-compose.yml
```
Replace these lines:
- `USER=YOUR_NORDVPN_USERNAME` → Your NordVPN service username
- `PASS=YOUR_NORDVPN_PASSWORD` → Your NordVPN service password  
- `NETWORK=192.168.0.0/24` → Your network range (most home networks use this)

### 6. Launch Everything
```bash
docker-compose up -d
```

### 7. Verify VPN Protection
```bash
# Check that downloads are protected by VPN
docker exec qbittorrent curl -s ifconfig.me
# Should show an Australian IP, NOT your real IP
```

## Access Your Services

Replace `192.168.0.167` with your server's IP from step 1:

**Daily Use:**
- **Request Movies/Shows**: http://192.168.0.167:5055
- **Watch Content**: http://192.168.0.167:8096

**One-Time Setup** (configure these once):
- **Download Client**: http://192.168.0.167:8080
- **TV Manager**: http://192.168.0.167:8989  
- **Movie Manager**: http://192.168.0.167:7878
- **Indexer Manager**: http://192.168.0.167:9117
- **System Admin**: http://192.168.0.167:9000 (optional - can be removed)

## First-Time Configuration

1. **qBittorrent** (8080): Change password from `admin`/`adminadmin`
2. **Prowlarr** (9117): Add indexers (torrent sites)
3. **Sonarr** (8989) & **Radarr** (7878): Connect to qBittorrent and Prowlarr using **internal IP addresses**
4. **Jellyfin** (8096): Add media libraries - if you get sync errors, recreate the container and ensure Jellyfin has folder access
5. **Jellyseerr** (5055): Connect to Sonarr, Radarr, and Jellyfin using **internal IP addresses**

⚠️ **Important**: When connecting services together, always use your server's **internal IP address** (e.g., `192.168.0.167`), not `localhost` or `127.0.0.1`

[Detailed setup instructions →](SETUP.md)

## How It Works

1. You request content in Jellyseerr
2. System automatically finds and downloads via VPN
3. Files are organized and made available in Jellyfin
4. You watch on any device

All torrent traffic goes through NordVPN. Management interfaces stay local for speed.

**Note**: Portainer (System Admin) is optional and can be removed from the docker-compose.yml if you don't need container management.

## Troubleshooting

**Can't access services?**
```bash
# Check if containers are running
docker ps

# Check your network settings in docker-compose.yml
# Most home networks use 192.168.0.0/24 or 192.168.1.0/24
```

**VPN not working?**
```bash
# Check VPN connection
docker logs nordvpn

# Verify you're using SERVICE credentials from NordVPN dashboard
# NOT your regular login email/password
```

**Services won't start?**
```bash
# View detailed logs
docker-compose logs
```

**Jellyfin sync errors?**
```bash
# Recreate Jellyfin container and ensure folder permissions
docker-compose down
sudo chown -R 1000:1000 ./media
docker-compose up -d jellyfin
```

## Files

- `docker-compose.yml` - Main configuration file
- `SETUP.md` - Detailed setup instructions  
- `TROUBLESHOOTING.md` - Common issues and solutions

---

**Legal**: Educational purposes only. Respect copyright laws and only download content you legally own.

**Questions?** Open an issue or check existing discussions.
```

## .env.example
```bash
# NordVPN Credentials (get from https://my.nordaccount.com/dashboard/nordvpn/)
NORDVPN_USERNAME=YOUR_NORDVPN_USERNAME
NORDVPN_PASSWORD=YOUR_NORDVPN_PASSWORD

# Network Configuration
# Most home networks use 192.168.0.0/24 or 192.168.1.0/24
LOCAL_NETWORK=192.168.0.0/24

# Timezone
TZ=Australia/Sydney

# User/Group IDs (run 'id' command to get yours)
PUID=1000
PGID=1000
```

## setup.sh
```bash
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
echo ""
echo "🔐 Verify VPN protection:"
echo "   docker exec qbittorrent curl -s ifconfig.me"
echo "   (Should show Australian IP, not your real IP)"
```

## SETUP.md
```markdown
# Detailed Setup Instructions

## Prerequisites

### Hardware Requirements
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 500GB minimum (1TB+ recommended)
- **Network**: Ethernet connection (WiFi will be slow for downloads)
- **CPU**: Any modern 64-bit processor

### Software Requirements
- Linux OS (Ubuntu, Debian, CentOS, etc.)
- Docker and Docker Compose
- NordVPN subscription with service credentials

## Step-by-Step Setup

### 1. Get NordVPN Service Credentials
1. Log into your [NordVPN Dashboard](https://my.nordaccount.com/dashboard/nordvpn/)
2. Go to "Manual Setup" or "Service Credentials"
3. Generate service username and password (NOT your regular login)

### 2. Clone Repository
```bash
git clone https://github.com/Harmanhrm/NordVpn-Personal-Media-Server.git
cd NordVpn-Personal-Media-Server
```

### 3. Run Setup Script
```bash
chmod +x setup.sh
./setup.sh
```

### 4. Configure Environment
```bash
cp .env.example .env
nano .env
```

Update the following:
- `NORDVPN_USERNAME`: Your service username
- `NORDVPN_PASSWORD`: Your service password
- `LOCAL_NETWORK`: Your home network range

### 5. Start Services
```bash
docker-compose up -d
```

### 6. Verify VPN Protection
```bash
# Check that downloads are using VPN
docker exec qbittorrent curl -s ifconfig.me
# Should show Australian IP, not your real IP
```

## Service Configuration

### qBittorrent (Port 8080)
1. Default login: `admin` / `adminadmin`
2. Change default password immediately
3. Go to Tools > Options > Web UI
4. Set alternative port if needed

### Prowlarr (Port 9117)
1. Add indexers (torrent sites)
2. Test indexers to ensure they work
3. Copy API key for other services

### Sonarr (Port 8989) - TV Shows
1. Go to Settings > Download Clients
2. Add qBittorrent:
   - Host: `YOUR_SERVER_IP` (e.g., `192.168.0.167`)
   - Port: `8080`
   - Username/Password from qBittorrent
3. Go to Settings > Indexers
4. Add Prowlarr:
   - Host: `YOUR_SERVER_IP`
   - Port: `9117`

### Radarr (Port 7878) - Movies
1. Same configuration as Sonarr but for movies
2. Use your server's internal IP for all connections
3. Set movie quality profiles
4. Configure folder structure

### Jellyfin (Port 8096)
1. Create admin account
2. Add media libraries:
   - Movies: `/data/movies`
   - TV Shows: `/data/tvshows`
3. Configure metadata providers
4. **If sync errors occur**: Stop container, fix permissions, recreate container