#!/bin/bash
### every exit != 0 fails the script
set -e

## resolve VNC geometry / password
mkdir -p "$HOME/.vnc"
echo "$VNC_PW" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

## minimal xstartup -> XFCE
cat > "$HOME/.vnc/xstartup" <<'XS'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
startxfce4 &
XS
chmod +x "$HOME/.vnc/xstartup"

## clean any stale lock, then start the VNC server on :1
vncserver -kill "$DISPLAY" >/dev/null 2>&1 || true
rm -f "/tmp/.X11-unix/X${DISPLAY#:}" "/tmp/.X${DISPLAY#:}-lock" || true
vncserver "$DISPLAY" -depth "$VNC_COL_DEPTH" -geometry "$VNC_RESOLUTION" \
    -localhost no -rfbport "$VNC_PORT" --I-KNOW-THIS-IS-INSECURE

## start noVNC (websockify) bridging NO_VNC_PORT -> VNC_PORT
/usr/share/novnc/utils/novnc_proxy \
    --vnc "localhost:${VNC_PORT}" \
    --listen "${NO_VNC_PORT}" >/dev/null 2>&1 &

echo "VNC up on :${VNC_PORT}, noVNC on :${NO_VNC_PORT}"

## keep the container in the foreground on the VNC server log
tail -f "$HOME/.vnc/"*"$DISPLAY.log"
