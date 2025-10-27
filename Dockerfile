FROM debian:12

# ESSIEM SYSTEMS - MetaTrader 4 Headless Server
LABEL maintainer="ESSIEM SYSTEMS"
LABEL version="1.0"
LABEL description="ESSIEM MetaTrader 4 Headless Server with VNC"

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt upgrade -y && \
    apt install -y sudo curl wget x11vnc xvfb supervisor git openssl

# Install Wine using same method as mt4debian.sh
RUN rm -f /etc/apt/sources.list.d/winehq* && \
    dpkg --add-architecture i386 && \
    mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -nc https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources && \
    mv winehq-bookworm.sources /etc/apt/sources.list.d/ && \
    apt update && \
    apt install -y --install-recommends winehq-stable

# Create mt4 user
RUN useradd -m -s /bin/bash mt4

# Download MT4
RUN wget "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4oldsetup.exe" -O /tmp/mt4setup.exe

# Set up noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify.git /opt/novnc/utils/websockify

# Generate SSL
RUN mkdir -p /opt/essiem-mt4/ssl && \
    openssl req -x509 -newkey rsa:4096 -keyout /opt/essiem-mt4/ssl/key.pem -out /opt/essiem-mt4/ssl/cert.pem -days 36500 -nodes -subj "/C=US/ST=ESSIEM/L=Trading/O=ESSIEM SYSTEMS/CN=essiem-mt4"

# Copy supervisor config
COPY supervisord.conf /etc/essiem-mt4/supervisord.conf

EXPOSE 6080

CMD ["/usr/bin/supervisord", "-c", "/etc/essiem-mt4/supervisord.conf"]
