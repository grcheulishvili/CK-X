# Running CK-X fully self-contained (no dependency on nishanb's images)

This simulator now builds entirely from this repository plus **official Docker Hub library
images** (`node`, `ubuntu`, `nginx`, `alpine`, `docker:dind`, `redis`) and the official
`k3d` release from `github.com/k3d-io`. Nothing is pulled from `nishanb/*`.

## What changed for independence

1. **App images build locally, never pulled.** Every service in `docker-compose.yaml` is
   retagged to a neutral namespace (`ckx/ck-x-simulator-*:local`) and marked
   `pull_policy: build`, so `docker compose up` can never fall back to pulling a
   `nishanb/*` image from Docker Hub. Always bring the stack up with a build:

   ```bash
   docker compose up -d --build
   ```

2. **The one external base image is removed as a hard dependency.** `remote-desktop`
   previously did `FROM nishanb/ck-x-simulator-vnc-base:v3`. That base is a
   ConSol headless-VNC image. The `FROM` is now an overridable build arg:

   ```dockerfile
   ARG VNC_BASE_IMAGE=consol/debian-xfce-vnc:nightly
   FROM ${VNC_BASE_IMAGE}
   ```

   The default points at the **public upstream** (ConSol), so the build no longer needs
   nishanb at all. If you want zero third-party base images either, build the fully
   self-hosted base in `./vnc-base` (below) and point the arg at it.

   **Verified:** `nishanb/ck-x-simulator-vnc-base:v3` was `consol/ubuntu-xfce-vnc`
   (Ubuntu 16.04, XFCE 4.12), which upstream has since deprecated in favour of the
   Debian-based images; the default now tracks `consol/debian-xfce-vnc` — confirmed from the running image's ConSol labels and its
   verbatim `vnc_startup.sh`. The swap is transparent because **all VNC settings are injected
   at runtime by `docker-compose.yaml`** (`VNC_PW` / `VNC_PASSWORD=bakku-the-wizard`,
   `VNC_RESOLUTION=1280x800`, `VNC_VIEW_ONLY=false`), and the webapp auto-connects noVNC with
   that same password — so whatever a base image bakes in is overridden. Nothing hardcodes a
   value that only `v3` had.

3. **The installer builds locally.** `scripts/install.sh` now uses the repo's own
   `docker-compose.yaml` when present and runs `docker compose build` instead of pulling
   prebuilt images.

## Tier 2: fully vendored VNC base (no ConSol either)

`./vnc-base` builds a headless XFCE + TigerVNC + noVNC desktop from `ubuntu:22.04`,
reproducing the contract `remote-desktop` needs (`/headless` home, an entrypoint at
`/dockerstartup/vnc_startup.sh` containing the `### every exit != 0 fails the script`
marker, VNC on 5901, noVNC on 6901, and `python3`).

```bash
docker build -t ckx/vnc-base:local vnc-base/
# then build remote-desktop on top of it:
docker compose build --build-arg VNC_BASE_IMAGE=ckx/vnc-base:local remote-desktop
docker compose up -d
```

To make it the permanent default, either export it once:

```bash
echo 'VNC_BASE_IMAGE=ckx/vnc-base:local' >> .env    # picked up by compose build args
```

or change the `ARG VNC_BASE_IMAGE=` default in `remote-desktop/Dockerfile`.

> **Status:** `v3` was ConSol `ubuntu-xfce-vnc` on **Ubuntu 16.04 / XFCE 4.12** (now EOL, so a
> faithful 16.04 rebuild is fragile — the apt archives have moved). This `vnc-base` is a
> **modernized equivalent on Ubuntu 22.04** that satisfies the same contract. It's the one
> piece that couldn't be verified against a live desktop here; if the desktop doesn't come up,
> check `docker logs ck-x-remote-desktop-1` — it's almost certainly the `vnc_startup.sh`
> VNC/noVNC invocation for your package versions. Tier 1 (ConSol default) is the exact `v3`
> lineage and already removes the nishanb dependency, so rely on that while tuning `vnc-base`.

## Optional: publish your own copies

If you'd rather not rebuild each time, push the locally built images to **your own** registry
and update the `image:` names — but keep `pull_policy: build` off only for the machines that
should pull. The point is that no name in this repo references `nishanb` anymore.
