#!/bin/bash
echo "ESSIEM SYSTEMS - MT4 Server Installer"
echo "One-Line Installation..."

# Install Docker and run ESSIEM MT4 Server
apt update && apt install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
systemctl enable docker && systemctl start docker
sleep 10

docker run -d \
    --name essiem-mt4 \
    --restart unless-stopped \
    -e VNC_PASSWORD=essiem123 \
    -p 6080:3000 \
    -v essiem-mt4-data:/home/mt4/program \
    p3ps1man/dockertrader-vnc

IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ INSTALLATION COMPLETE!"
echo "🌐 Access: https://$IP_ADDRESS:6080/vnc.html"
echo "🔑 Password: essiem123"
echo ""
echo "ESSIEM SYSTEMS - MT4 Trading Server Ready 🚀"
