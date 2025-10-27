#!/bin/bash
set -e

echo "================================================"
echo "   ESSIEM SYSTEMS - MT4 HEADLESS SERVER"
echo "================================================"

# -----------------------------
# 1️⃣ Install dependencies for headless MT4
# -----------------------------
echo "📦 Installing dependencies..."
apt update && apt upgrade -y
apt install -y sudo curl wget x11vnc xvfb supervisor git openssl

# -----------------------------
# 2️⃣ Install Wine using the same method as mt4debian.sh
# -----------------------------
echo "🍷 Installing Wine..."
sudo rm -f /etc/apt/sources.list.d/winehq*
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

# Get Debian version and choose correct repository
OS_VER=$(lsb_release -r | cut -f2 | cut -d "." -f1)
if (( $OS_VER >= 13)); then
  wget -nc https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources
  sudo mv winehq-trixie.sources /etc/apt/sources.list.d/
elif (( $OS_VER < 13 )) && (( $OS_VER >= 12 )); then
  wget -nc https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
  sudo mv winehq-bookworm.sources /etc/apt/sources.list.d/
elif (( $OS_VER < 12 )) && (( $OS_VER >= 11 )); then
  wget -nc https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources
  sudo mv winehq-bullseye.sources /etc/apt/sources.list.d/
elif (( $OS_VER <= 10 )); then
  wget -nc https://dl.winehq.org/wine-builds/debian/dists/buster/winehq-buster.sources
  sudo mv winehq-buster.sources /etc/apt/sources.list.d/
fi

sudo apt update
sudo apt install -y --install-recommends winehq-stable

# -----------------------------
# 3️⃣ Download and install MT4 headlessly
# -----------------------------
echo "📥 Downloading MT4..."
wget "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4oldsetup.exe" -O /tmp/mt4setup.exe

echo "🔄 Installing MT4 headlessly with xvfb..."
export WINEPREFIX=/home/mt4/.mt4
export DISPLAY=:1

# Initialize Wine and install MT4 in headless mode
mkdir -p /home/mt4/.mt4
xvfb-run -a wineboot --init
sleep 10
xvfb-run -a winecfg -v=win10
sleep 5
xvfb-run -a wine /tmp/mt4setup.exe /S
sleep 60

# Clean up
rm -f /tmp/mt4setup.exe

# -----------------------------
# 4️⃣ Set up noVNC for web access
# -----------------------------
echo "🌐 Setting up VNC..."
git clone https://github.com/novnc/noVNC.git /opt/novnc
git clone https://github.com/novnc/websockify.git /opt/novnc/utils/websockify

# Generate SSL certificates
mkdir -p /opt/essiem-mt4/ssl
openssl req -x509 -newkey rsa:4096 -keyout /opt/essiem-mt4/ssl/key.pem -out /opt/essiem-mt4/ssl/cert.pem -days 36500 -nodes -subj "/C=US/ST=ESSIEM/L=Trading/O=ESSIEM SYSTEMS/CN=essiem-mt4"

# -----------------------------
# 5️⃣ Create supervisor configuration
# -----------------------------
echo "⚙️ Creating supervisor configuration..."
mkdir -p /etc/essiem-mt4

cat << 'SUPERVISOR_EOF' > /etc/essiem-mt4/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:xvfb]
command=/usr/bin/Xvfb :1 -screen 0 1600x800x24
autorestart=true
priority=100

[program:x11vnc]
command=/usr/bin/x11vnc -display :1 -forever -shared -rfbport 5901 -passwd essiem123
autorestart=true
priority=200
depends_on=xvfb

[program:novnc]
command=python3 /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080 --ssl-only --cert /opt/essiem-mt4/ssl/cert.pem --key /opt/essiem-mt4/ssl/key.pem
autorestart=true
priority=300
depends_on=x11vnc

[program:mt4]
command=wine /home/mt4/.mt4/drive_c/Program\ Files/MetaTrader\ 4/terminal.exe
autorestart=true
priority=400
environment=WINEPREFIX="/home/mt4/.mt4",DISPLAY=":1"
startsecs=10
SUPERVISOR_EOF

# -----------------------------
# 6️⃣ Create systemd service
# -----------------------------
echo "🔧 Creating system service..."
cat << 'SERVICE_EOF' > /etc/systemd/system/essiem-mt4.service
[Unit]
Description=ESSIEM MT4 Headless Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/supervisord -c /etc/essiem-mt4/supervisord.conf
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Start the service
systemctl daemon-reload
systemctl enable essiem-mt4
systemctl start essiem-mt4

# -----------------------------
# 7️⃣ Done
# -----------------------------
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo ""
echo "🎉 HEADLESS MT4 INSTALLATION COMPLETE!"
echo "====================================="
echo "🌐 Access: https://$IP_ADDRESS:6080/vnc.html"
echo "🔑 Password: essiem123"
echo ""
echo "MT4 is running headlessly with VNC access"
echo "ESSIEM SYSTEMS - MT4 Trading Server Ready 🚀"

# Wait a bit and check status
sleep 5
echo ""
echo "🔍 Service status:"
systemctl status essiem-mt4 --no-pager -l
