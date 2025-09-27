# GitHub Repository Structure for NordVPN Media Stack

## Repository Files to Create

### 1. `docker-compose.yml`
```yaml
version: '3.8'

services:
  nordvpn:
    image: azinchen/nordvpn:latest
    container_name: nordvpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      - USER=YOUR_NORDVPN_USERNAME
      - PASS=YOUR_NORDVPN_PASSWORD
      - COUNTRY=Australia
      - NETWORK=192.168.0.0/24
      - OPENVPN_OPTS=--mute-replay-warnings
    ports:
      - "8080:8080"   # qBittorrent
      - "9117:9696"   # Prowlarr (mapped to 9117 externally)
      - "8989:8989"   # Sonarr
      - "7878:7878"   # Radarr
      - "5055:5055"   # Jellyseerr
      - "8096:8096"   # Jellyfin
      - "9000:9000"   # Portainer
      - "9443:9443"   # Portainer HTTPS
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "service:nordvpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Australia/Sydney
      - WEBUI_PORT=8080
    volumes:
      - ./config/qbittorrent:/config
      - ./media/downloads:/downloads
      - ./media:/media
    depends_on:
      - nordvpn
    restart: unless-stopped

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    network_mode: "service:nordvpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Australia/Sydney
    volumes:
      - ./config/prowlarr:/config
    depends_on:
      - nordvpn
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    network_mode: "service:nordvpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Australia/Sydney
    volumes:
      - ./config/sonarr:/config
      - ./media/tv:/tv
      - ./media/downloads:/downloads
    depends_on:
      - nordvpn
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    network_mode: "service:nordvpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Australia/Sydney
    volumes:
      - ./config/radarr:/config
      - ./media/movies:/movies
      - ./media/downloads:/downloads
    depends_on:
      - nordvpn
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    network_mode: "service:nordvpn"
    environment:
      - LOG_LEVEL=debug
      - TZ=Australia/Sydney
    volumes:
      - ./config/jellyseerr:/app/config
    depends_on:
      - nordvpn
    restart: unless-stopped

  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    network_mode: "service:nordvpn"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Australia/Sydney
    volumes:
      - ./config/jellyfin:/config
      - ./media/tv:/data/tvshows
      - ./media/movies:/data/movies
    depends_on:
      - nordvpn
    restart: unless-stopped

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    network_mode: "service:nordvpn"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    depends_on:
      - nordvpn
    restart: unless-stopped

volumes:
  portainer_data:
```

### 2. `.env.example`
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

### 3. `setup.sh`
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

### 4. `SETUP.md`
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

### Jellyseerr (Port 5055)
1. Connect to Jellyfin server using `http://YOUR_SERVER_IP:8096`
2. Add Sonarr: `http://YOUR_SERVER_IP:8989`
3. Add Radarr: `http://YOUR_SERVER_IP:7878`
4. Configure user permissions

## Directory Structure
```
mediastack/
├── docker-compose.yml
├── .env
├── media/
│   ├── downloads/
│   ├── movies/
│   └── tv/
└── config/
    ├── qbittorrent/
    ├── prowlarr/
    ├── sonarr/
    ├── radarr/
    ├── jellyseerr/
    └── jellyfin/
```

## Security Notes
- All torrent traffic is routed through NordVPN
- Management interfaces are local-only
- Change all default passwords
- Consider using a reverse proxy for external access
```

### 5. `TROUBLESHOOTING.md`
```markdown
# Troubleshooting Guide

## Common Issues

### Services Won't Start
```bash
# Check container status
docker ps -a

# View logs for specific service
docker-compose logs nordvpn
docker-compose logs qbittorrent

# Restart all services
docker-compose down
docker-compose up -d
```

### Can't Access Web Interfaces
1. **Check your server IP**:
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. **Verify port forwarding** (if accessing remotely)

3. **Check firewall rules**:
   ```bash
   # Ubuntu/Debian
   sudo ufw status
   sudo ufw allow 8080,8989,7878,9117,5055,8096,9000/tcp
   ```

### VPN Not Working
1. **Check NordVPN container logs**:
   ```bash
   docker logs nordvpn
   ```

2. **Common issues**:
   - Using email/password instead of service credentials
   - Wrong network range in NETWORK environment variable
   - Firewall blocking VPN connection

3. **Test VPN connection**:
   ```bash
   # Should show Australian IP
   docker exec qbittorrent curl -s ifconfig.me
   
   # Should show your real IP
   curl -s ifconfig.me
   ```

### Downloads Not Starting
1. **Check qBittorrent connection** in Sonarr/Radarr settings - ensure using internal IP
2. **Verify Prowlarr indexers** are working  
3. **Check download permissions**:
   ```bash
   ls -la media/downloads/
   # Should be owned by your user
   ```

### Jellyfin Issues
**Sync Errors / Library Problems**:
```bash
# Stop services
docker-compose down

# Fix permissions
sudo chown -R 1000:1000 ./media ./config

# Recreate Jellyfin container
docker-compose up -d jellyfin

# Check Jellyfin logs
docker logs jellyfin
```

**Connection Issues**:
- Always use internal IP addresses when connecting services
- Never use `localhost` or `127.0.0.1` between containers
- Example: Use `http://192.168.0.167:8096` not `http://localhost:8096`

### Permission Issues
```bash
# Fix ownership
sudo chown -R $USER:$USER ./media ./config

# Fix permissions
chmod -R 755 ./media ./config
```

### Network Issues
1. **Wrong network range**: Most home networks use `192.168.0.0/24` or `192.168.1.0/24`
2. **Docker network conflicts**: Try restarting Docker daemon
3. **ISP blocking**: Some ISPs block VPN traffic

### Container Keeps Restarting
```bash
# Check specific container logs
docker logs --tail 50 CONTAINER_NAME

# Common causes:
# - Insufficient memory
# - Permission issues
# - Network conflicts
# - Invalid configuration
```

## Performance Optimization

### Slow Downloads
1. Use wired ethernet connection
2. Increase qBittorrent connection limits
3. Choose closer VPN servers
4. Ensure adequate storage space

### High CPU Usage
1. Limit concurrent downloads in qBittorrent
2. Reduce video transcoding quality in Jellyfin
3. Monitor with `htop` or `docker stats`

### Storage Management
```bash
# Check disk usage
df -h

# Clean up old downloads
docker exec qbittorrent rm -rf /downloads/completed/old_stuff

# Clean Docker images
docker system prune -a
```

## Getting Help
1. Check existing GitHub issues
2. Include logs when reporting problems
3. Specify your OS and Docker version
4. Test with minimal configuration first
```

### 6. `.gitignore`
```
# Environment files
.env
.env.local
.env.*.local

# Config directories (contains user data)
config/

# Media directories
media/

# Logs
*.log
logs/

# Backup files
*.backup
*.bak

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Docker
docker-compose.override.yml

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
```

### 7. `LICENSE`
```
MIT License

Copyright (c) 2025 [Harmanbyte]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```