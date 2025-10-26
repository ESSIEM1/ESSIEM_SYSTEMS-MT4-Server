#!/bin/bash
set -e
echo "================================================"
echo "   ESSIEM SYSTEMS - MT4 SERVER INSTALLER"
echo "================================================"
echo "INSTALLING ON FRESH SYSTEM..."
echo ""
echo "📦 Updating system and installing prerequisites..."
apt update
apt upgrade -y
apt install -y curl wget sudo gnupg2
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi
echo "⏳ Waiting for Docker to start..."
sleep 10
echo "🧹 Cleaning up any existing containers..."
docker stop essiem-mt4 2>/dev/null || true
docker rm essiem-mt4 2>/dev/null || true
echo "🚀 Starting ESSIEM MT4 VNC Server..."
docker run -d \
    --name essiem-mt4 \
    --restart unless-stopped \
    -e VNC_PASSWORD=essiem123 \
    -p 6080:3000 \
    -v essiem-mt4-data:/home/mt4/program \
    p3ps1man/dockertrader-vnc

echo "⏳ Waiting for VNC to start..."
sleep 15
echo "🔍 Testing VNC connection..."
if curl -k -s https://localhost:6080/vnc.html > /dev/null; then
    echo "✅ VNC is working!"
else
    echo "⚠️ VNC might be starting slowly..."
    docker logs essiem-mt4 --tail 5
fi

IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo ""
echo "🎉 INSTALLATION COMPLETE!"
echo "========================"
echo "🌐 Access VNC at: https://$IP_ADDRESS:6080/vnc.html"
echo "🔑 Password: essiem123"
echo ""
echo "✅ Features:"
echo "   - Auto-restart on failure/reboot"
echo "   - Persistent data storage"
echo "   - Web-based VNC access"
echo "   - ESSIEM branded"
echo ""
echo "⚠️ Important:"
echo "   - Use HTTPS (not HTTP)"
echo "   - Browser will show SSL warning"
echo "   - Click 'Advanced' → 'Proceed to site'"
echo ""
echo "ESSIEM SYSTEMS - MT4 Trading Server Ready 🚀"
