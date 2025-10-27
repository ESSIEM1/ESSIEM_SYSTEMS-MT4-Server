#!/bin/bash
echo "ESSIEM SYSTEMS - MT4 Headless Server Installer"
echo "One-Line Installation..."

apt update && apt install -y curl
curl -fsSL https://raw.githubusercontent.com/ESSIEM1/ESSIEM_SYSTEMS-MT4-Server/main/install-essiem-mt4.sh | bash
