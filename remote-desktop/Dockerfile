# Base Image (headless XFCE + TigerVNC + noVNC).
# Default is the public upstream so the build never depends on nishanb's registry.
# For a fully self-hosted base, build ./vnc-base and pass
#   --build-arg VNC_BASE_IMAGE=ckx/vnc-base:local
ARG VNC_BASE_IMAGE=consol/ubuntu-xfce-vnc:1.3.0
FROM ${VNC_BASE_IMAGE}

# Switch to root user for installations
USER 0

# Update and install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    ssh-client \
    telnet \
    nano \
    vim \
    curl \
    wget \
    xclip

#create candidate user
RUN useradd -m candidate

#set hostname as terminal
RUN echo "export HOSTNAME=terminal" >> /headless/.bashrc
#set terminal to bash
RUN echo "export TERM=xterm" >> /headless/.bashrc

#when shell open switch to candidate user
RUN echo "cd /home/candidate && su candidate" >> /headless/.bashrc

#disable asking for ssh host verification
RUN mkdir -p /home/candidate/.ssh
RUN touch /home/candidate/.ssh/config
RUN echo "StrictHostKeyChecking no" >> /home/candidate/.ssh/config
RUN echo "UserKnownHostsFile /dev/null" >> /home/candidate/.ssh/config


# Flat, solid desktop for VNC performance (see desktop-tune.sh).
# Shipped as xfconf XML so the very first paint is already solid.
COPY xfce/xfce4-desktop.xml /headless/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
COPY xfce/xfwm4.xml         /headless/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
RUN chmod -R 0777 /headless/.config

# Belt and braces: overwrite every stock backdrop with a solid-colour image.
# xfdesktop renders whatever file is configured, so replacing the file content
# guarantees a flat background even if a config we don't control wins.
# (GdkPixbuf sniffs content, so a PNG kept under a .jpg name still loads.)
COPY xfce/solid-bg.png /usr/share/backgrounds/ckx-solid.png
RUN set -eux; \
    for d in /usr/share/xfce4/backdrops /usr/share/backgrounds/xfce; do \
        [ -d "$d" ] || continue; \
        for f in "$d"/*; do [ -f "$f" ] && cp -f /usr/share/backgrounds/ckx-solid.png "$f"; done; \
    done; true

COPY desktop-tune.sh /usr/local/bin/desktop-tune.sh
RUN chmod +x /usr/local/bin/desktop-tune.sh

# Copy startup script
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

COPY agent.py /tmp/agent.py

RUN sed -i '/### every exit != 0 fails the script/a /usr/local/bin/startup.sh' /dockerstartup/vnc_startup.sh
