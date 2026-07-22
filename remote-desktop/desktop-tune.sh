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

# Wait for the X server (started by vnc_startup.sh) to accept connections.
for _ in $(seq 1 60); do
    if xset q >/dev/null 2>&1 || xrdb -query >/dev/null 2>&1; then break; fi
    sleep 1
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
# monitorVirtual-1 ...), so enumerate whatever this session actually created
# instead of guessing a path.
for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/image-style$'); do
    xfconf-query -c xfce4-desktop -p "$prop" -s 0 >/dev/null 2>&1
done
for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/color-style$'); do
    xfconf-query -c xfce4-desktop -p "$prop" -s 0 >/dev/null 2>&1
done
for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$'); do
    xfconf-query -c xfce4-desktop -p "$prop" -s "$SOLID" >/dev/null 2>&1
done

# If xfdesktop had already painted the stock wallpaper, make it re-read the config.
if command -v xfdesktop >/dev/null 2>&1; then
    xfdesktop --reload >/dev/null 2>&1 &
fi

# Last resort: if xfdesktop is still drawing something, drop it and leave the
# solid root window. The lab desktop needs no icons or desktop right-click menu.
sleep 3
if [ "${CKX_KILL_XFDESKTOP:-false}" = "true" ]; then
    pkill -x xfdesktop >/dev/null 2>&1
    xsetroot -solid "$BG" >/dev/null 2>&1
fi

exit 0
