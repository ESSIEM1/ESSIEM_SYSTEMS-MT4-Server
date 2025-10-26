FROM essiem1/essiem-mt5-vnc:latest

# ESSIEM SYSTEMS - MetaTrader 4 VNC Server
LABEL maintainer="ESSIEM SYSTEMS"
LABEL version="1.0"
LABEL description="ESSIEM MetaTrader 4 VNC Server with Auto-Restart"

ENV VNC_PORT=5901 \
    RESOLUTION=1920x1080 \
    WEB_PORT=3000 \
    SUPERVISORD_PIDFILE=/home/mt4/.supervisor/supervisord.pid \
    SUPERVISORD_LOGFILE=/home/mt4/.supervisor/supervisord.log \
    CERT=/home/mt4/ssl/cert.pem \
    KEY=/home/mt4/ssl/key.pem \
    VNC_PASSWORD=changeme \
    MT4_RESOLUTION=1600x800

USER root

# Create mt4 user
RUN useradd -m -s /bin/bash mt4 && \
    echo 'mt4 ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER mt4
WORKDIR /home/mt4

RUN mkdir .supervisor && mkdir ssl
RUN openssl req -x509 -newkey rsa:4096 -keyout ssl/key.pem -out ssl/cert.pem -days 36500 -nodes -subj "/C=US/ST=ESSIEM/L=Trading/O=ESSIEM SYSTEMS/CN=essiem-mt4"

COPY supervisord.conf .supervisor/supervisord.conf

CMD ["/usr/bin/supervisord", "-c", ".supervisor/supervisord.conf"]
