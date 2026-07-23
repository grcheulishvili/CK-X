# Reading the Kubernetes docs during a lab

## Recommended: keep the docs in your own browser

The exam view now has a **"Send text to the lab clipboard"** panel under the terminal.

1. Open `https://kubernetes.io/docs` in your normal browser, on your own machine.
2. Copy the snippet you want.
3. Paste it into the panel and press **Send to VM** (or Ctrl/Cmd+Enter).
4. In the lab terminal, paste with **Ctrl+Shift+V**.

This sidesteps both problems with browsing inside the VM: your own browser is
current, and it already trusts your corporate TLS-inspection certificate. It is
also closer to the real exam, where the docs open in a separate browser tab.

The text is placed on both X selections, so Ctrl+Shift+V (terminal), Ctrl+V
(applications) and middle-click all work.

## If you do want to browse inside the VM

### 1. SSL errors ("connection is not private")

These come from a corporate proxy re-signing TLS with a private CA that the VM
does not trust. Install that CA:

1. Export your organisation's **root** CA as a PEM `.crt`
   (see `remote-desktop/certs/README.md` for how to export it per platform).
2. Drop the file into `remote-desktop/certs/`.
3. Rebuild: `docker compose up -d --build remote-desktop`

The build installs every `.crt` there into the system trust store
(`update-ca-certificates`) and writes a Firefox enterprise policy pointing at the
same files, because Firefox keeps its own trust store separate from the system one.

Never disable certificate validation to work around this - install the CA instead.

### 2. Browsers

The desktop now builds on **`consol/debian-xfce-vnc:nightly`**, the maintained ConSol
image, which ships current Firefox and Chromium. The previous default
(`consol/ubuntu-xfce-vnc`) was Ubuntu 16.04, last updated in 2018, and its browsers were
far too old to render the docs site correctly.

Nothing to do: `docker compose up -d --build` picks it up.

Notes:

- The base is pinned to a tag, not a digest. To pin harder, pass your own:
  `docker compose build --build-arg VNC_BASE_IMAGE=consol/debian-xfce-vnc@sha256:... remote-desktop`
- `shm_size: 256m` is set for the desktop container. Containers default to a 64MB
  `/dev/shm`, which makes Chromium crash on graphics-heavy pages at higher resolutions.
- The image is ~736MB, so the first build pulls a fair amount.
- The build now *verifies* that it can inject into ConSol's `vnc_startup.sh`. If upstream
  ever renames the marker it hooks, the build fails loudly instead of silently producing a
  desktop with no clipboard agent.

### Fully self-hosted alternative

If you would rather depend on no third-party image at all, `vnc-base/` builds an
equivalent desktop from `ubuntu:22.04` (Firefox included):

```bash
docker build -t ckx/vnc-base:local vnc-base/
docker compose build --build-arg VNC_BASE_IMAGE=ckx/vnc-base:local remote-desktop
docker compose up -d
```

Certificates work the same way there: `vnc-base/certs/`.

> This self-hosted base is the one piece not verified against a live desktop here. The
> ConSol default above is the tested path.
