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
      xclip openssh-client software-properties-common gnupg \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# A current browser, so kubernetes.io renders correctly (the old 16.04 base shipped
# a Firefox/Chromium too old for the docs site).
#
# NOTE: on Ubuntu 22.04 the `firefox` apt package is a transitional stub that
# installs a *snap*, which cannot run in a container. The Mozilla team PPA ships a
# real .deb, so it is pinned above the stub.
ARG INSTALL_BROWSER=true
RUN if [ "$INSTALL_BROWSER" = "true" ]; then \
      add-apt-repository -y ppa:mozillateam/ppa \
   && printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
        > /etc/apt/preferences.d/mozilla-firefox \
   && apt-get update \
   && apt-get install -y --no-install-recommends firefox \
   && apt-get clean && rm -rf /var/lib/apt/lists/*; \
    fi

# Corporate / custom root CAs (see remote-desktop/certs/README.md).
COPY certs/ /usr/local/share/ca-certificates/ckx/
RUN update-ca-certificates || true \
 && mkdir -p /etc/firefox/policies \
 && CERTS=$(ls /usr/local/share/ca-certificates/ckx/*.crt 2>/dev/null | sed 's/.*/"&"/' | paste -sd, -) \
 && printf '{\n  "policies": {\n    "Certificates": { "ImportEnterpriseRoots": true, "Install": [%s] },\n    "DisableTelemetry": true,\n    "OverrideFirstRunPage": "",\n    "DontCheckDefaultBrowser": true\n  }\n}\n' "$CERTS" > /etc/firefox/policies/policies.json

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
