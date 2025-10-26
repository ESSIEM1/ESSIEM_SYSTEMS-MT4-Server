#!/bin/bash
echo "================================================"
echo "   ESSIEM SYSTEMS - MT4 SERVER"
echo "================================================"
echo "Using ESSIEM stable image - proven to work!"

apt update && apt install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
systemctl enable docker && systemctl start docker
sleep 10

docker stop essiem-mt4 2>/dev/null || true
docker rm essiem-mt4 2>/dev/null || true

# Use OUR working ESSIEM image
docker run -d \
    --name essiem-mt4 \
    --restart unless-stopped \
    -e VNC_PASSWORD=essiem123 \
    -p 6080:3000 \
    -v essiem-mt4-data:/home/mt4/program \
    essiem1/essiem-mt4-vnc:latest

sleep 20

IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ INSTALLATION COMPLETE!"
echo "🌐 MT4 Terminal: https://$IP_ADDRESS:6080/vnc.html"
echo "🔑 Password: essiem123"
echo ""
echo "ESSIEM SYSTEMS - MT4 Trading Server Ready 🚀"
