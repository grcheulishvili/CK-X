# Fully self-hosted headless desktop base — built from ubuntu, no third-party image.
# Provides the same contract the remote-desktop image expects from the old
# nishanb/ck-x-simulator-vnc-base:v3 (which was a ConSol headless-vnc image):
#   - a /headless home with a .bashrc
#   - /dockerstartup/vnc_startup.sh as the entrypoint, containing the marker line
#     "### every exit != 0 fails the script" (remote-desktop sed-injects into it)
#   - XFCE desktop + TigerVNC (:5901) + noVNC/websockify web UI (:6901)
#   - python3 available (remote-desktop runs agent.py)
#
# Build:  docker build -t ckx/vnc-base:local vnc-base/
# Use:    docker compose build --build-arg VNC_BASE_IMAGE=ckx/vnc-base:local remote-desktop
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword

RUN apt-get update && apt-get install -y --no-install-recommends \
      xfce4 xfce4-terminal xterm dbus-x11 \
      tigervnc-standalone-server tigervnc-common \
      novnc websockify \
      python3 python3-numpy \
      net-tools procps sudo curl wget ca-certificates locales \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# noVNC entry page -> point the root at vnc.html
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html || true

# Headless home + startup dir
RUN mkdir -p $HOME $STARTUPDIR $HOME/.vnc \
    && touch $HOME/.bashrc

COPY vnc_startup.sh $STARTUPDIR/vnc_startup.sh
RUN chmod +x $STARTUPDIR/vnc_startup.sh \
    && chmod -R 0777 $HOME $STARTUPDIR

EXPOSE $VNC_PORT $NO_VNC_PORT
WORKDIR $HOME
ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
