#!/bin/bash
# Flatten the lab desktop: solid background, no compositing, no screen blanking.
#
# Over a VNC link every gradient, wallpaper and composited shadow becomes pixel
# data on the wire. A solid backdrop and a non-composited WM cut the amount of
# screen that changes per redraw, which is the single biggest factor in how
# responsive the desktop feels during a two-hour lab.
#
# Runs in the background from startup.sh. Everything is best-effort: this must
# never fail the container start, and it only uses tools already in the image.

BG="#0f1720"
SOLID="/usr/share/backgrounds/ckx-solid.png"

export DISPLAY="${DISPLAY:-:1}"

# --- Watchdog -------------------------------------------------------------
# ConSol redirects the vncserver command's output to a file, so when Xvnc fails
# the container still looks fine: noVNC keeps serving on 6901, nothing listens on
# 5901, and the browser just says "connection is closed" with no reason anywhere
# in `docker compose logs`. Surface the actual error on stderr so it shows up
# there. Runs detached; never affects startup.
(
    sleep 25
    # Probe the X11 socket, never the VNC port: connecting to 5901 and dropping
    # is what TigerVNC blacklists, and blacklisting 127.0.0.1 breaks websockify.
    if [ -S /tmp/.X11-unix/X1 ]; then
        echo "[ckx] Xvnc is running (X11 socket present)." >&2
    else
        echo "[ckx] ===============================================================" >&2
        echo "[ckx] Xvnc IS NOT RUNNING - the desktop will not load." >&2
        echo "[ckx] Dumping the startup logs that ConSol writes to disk:" >&2
        for f in /dockerstartup/*.log "$HOME"/.vnc/*.log /root/.vnc/*.log; do
            [ -f "$f" ] || continue
            echo "[ckx] --- $f ---" >&2
            tail -n 40 "$f" >&2
        done
        echo "[ckx] ===============================================================" >&2
    fi
) &
# --------------------------------------------------------------------------

# Wait for the X server (started by vnc_startup.sh) to accept connections.
for _ in $(seq 1 60); do
    if xset q >/dev/null 2>&1 || xrdb -query >/dev/null 2>&1; then break; fi
    sleep 1
done

# Terminal readability: load our X resources (zutty/xterm font + colours).
# Best-effort: a missing file or xrdb must never stop the desktop coming up.
for RES in /etc/X11/Xresources.ckx "$HOME/.Xresources" /root/.Xresources; do
    [ -f "$RES" ] && xrdb -merge "$RES" >/dev/null 2>&1
done

# Solid root window, and no blanking/power management during a long exam.
xsetroot -solid "$BG" >/dev/null 2>&1
xset s off >/dev/null 2>&1
xset s noblank >/dev/null 2>&1
xset -dpms >/dev/null 2>&1

# xfconf comes up with the session; give it a moment.
for _ in $(seq 1 30); do
    if xfconf-query -c xfwm4 -l >/dev/null 2>&1; then break; fi
    sleep 1
done

# Window manager: no compositing, wireframe move/resize (far less redraw).
xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false >/dev/null 2>&1 \
    || xfconf-query -c xfwm4 -p /general/use_compositing -s false >/dev/null 2>&1
for prop in /general/box_move /general/box_resize; do
    xfconf-query -c xfwm4 -p "$prop" -n -t bool -s true >/dev/null 2>&1 \
        || xfconf-query -c xfwm4 -p "$prop" -s true >/dev/null 2>&1
done

# Backdrop: monitor property names vary by X/VNC setup (monitor0, monitorVNC-0,
# monitorVirtual-1 ...) and the properties only exist once xfdesktop has painted
# at least once. Retry for a while instead of a single early pass.
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$'); do
        xfconf-query -c xfce4-desktop -p "$prop" -s "$SOLID" >/dev/null 2>&1
    done
    for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/image-style$'); do
        xfconf-query -c xfce4-desktop -p "$prop" -s 0 >/dev/null 2>&1
    done
    for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/color-style$'); do
        xfconf-query -c xfce4-desktop -p "$prop" -s 0 >/dev/null 2>&1
    done
    # Also write the paths xfdesktop uses before any monitor is enumerated.
    for base in /backdrop/screen0/monitor0/workspace0 \
                /backdrop/screen0/monitorVNC-0/workspace0 \
                /backdrop/screen0/monitorscreen/workspace0; do
        xfconf-query -c xfce4-desktop -p "$base/image-style" -n -t int -s 0 >/dev/null 2>&1
        xfconf-query -c xfce4-desktop -p "$base/last-image" -n -t string -s "$SOLID" >/dev/null 2>&1
    done
    xfdesktop --reload >/dev/null 2>&1
    sleep 3
done

# Last resort: if a wallpaper is still being drawn, drop xfdesktop and leave the
# solid root window. The lab desktop needs no icons or desktop right-click menu.
if [ "${CKX_KILL_XFDESKTOP:-false}" = "true" ]; then
    pkill -x xfdesktop >/dev/null 2>&1
    xsetroot -solid "$BG" >/dev/null 2>&1
fi

exit 0
