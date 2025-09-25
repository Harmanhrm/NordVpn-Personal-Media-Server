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
# Download the docker-compose.yml file
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/nordvpn-mediastack/main/docker-compose.yml
```

### 5. Add Your NordVPN Credentials
```bash
# Edit the configuration file
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
- **System Admin**: http://192.168.0.167:9000

## First-Time Configuration

1. **qBittorrent** (8080): Change password from `admin`/`adminadmin`
2. **Prowlarr** (9117): Add indexers (torrent sites)
3. **Sonarr** (8989) & **Radarr** (7878): Connect to qBittorrent and Prowlarr  
4. **Jellyfin** (8096): Add media libraries
5. **Jellyseerr** (5055): Connect to Sonarr, Radarr, and Jellyfin

[Detailed setup instructions →](SETUP.md)

## How It Works

1. You request content in Jellyseerr
2. System automatically finds and downloads via VPN
3. Files are organized and made available in Jellyfin
4. You watch on any device

All torrent traffic goes through NordVPN. Management interfaces stay local for speed.

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

## Files

- `docker-compose.yml` - Main configuration file
- `SETUP.md` - Detailed setup instructions  
- `TROUBLESHOOTING.md` - Common issues and solutions

---

**Legal**: Educational purposes only. Respect copyright laws and only download content you legally own.

**Questions?** Open an issue or check existing discussions.
