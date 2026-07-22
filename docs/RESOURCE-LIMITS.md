# Resource limits and blast radius

The simulator hands a candidate a root shell on a privileged container. That is fine for a
practice environment, but a mistake in a lab (or a deliberate `:(){ :|:& };:`) should stay
inside the container it happened in. This is what is enforced and, just as importantly,
what is not.

## What is enforced

Every service in `docker-compose.yaml` has:

| Control | Key | Why |
|---|---|---|
| CPU ceiling | `deploy.resources.limits.cpus` | Caps CPU *time*, so the host stays responsive |
| Memory ceiling | `deploy.resources.limits.memory` | Container is OOM-killed instead of the host swapping |
| **Process ceiling** | `deploy.resources.limits.pids` | **The control that actually stops a fork bomb** |
| FD ceiling | `ulimits.nofile` | Stops file-descriptor exhaustion |
| Log growth | `logging.options.max-size` / `max-file` | A looping container cannot fill the disk with logs |

Current budgets:

| Service | CPU | Memory | PIDs | nofile |
|---|---|---|---|---|
| k8s-api-server (privileged, dind + k3s) | 2 | 4G | 8192 | 65536 |
| jumphost (privileged) | 1 | 1G | 1024 | 16384 |
| remote-desktop | 1 | 1G | 1024 | 8192 |
| facilitator | 0.5 | 512M | 512 | 8192 |
| webapp | 0.5 | 512M | 512 | 8192 |
| remote-terminal | 0.5 | 512M | 256 | 8192 |
| nginx | 0.2 | 256M | 256 | 8192 |
| redis | 0.3 | 256M | 256 | 8192 |

### Why the PID limit is the one that matters

CPU and memory limits do **not** stop a fork bomb. A fork bomb's damage is PID exhaustion:
it consumes entries in the kernel's process table, which is a host-wide resource. Once it
is empty, the *host* cannot spawn new processes either, and you often cannot even open a
shell to kill it.

The `pids` limit uses the cgroup `pids` controller, which is a hard, kernel-enforced ceiling on
the number of processes in that container's cgroup. When a fork bomb hits it, `fork()`
starts returning `EAGAIN`. The container becomes unusable and the CPU quota keeps it from
saturating the machine, but the host PID table is untouched. Recovery is
`docker compose restart <service>`.

To verify, inside the lab node:

```bash
cat /sys/fs/cgroup/pids.max        # cgroup v2
# then, if you want to prove it (the container will need a restart afterwards):
:(){ :|:& };:
```

### Pinning to specific cores

`cpus: "2"` is a *quota* (two cores' worth of time, spread over any core). If you would
rather confine a container to specific physical cores, add `cpuset` alongside it:

```yaml
    cpuset: "0,1"     # only ever runs on CPU 0 and 1
```

Core indices are host-specific, so this is not set by default. The quota is usually the
better tool: it survives moving the project to another machine.

## Disk: read this before assuming it is capped

Disk is the one limit that is **not** enforced by default, and the reason is a real
platform constraint rather than an oversight.

The obvious control is:

```yaml
    storage_opt:
      size: "20G"
```

> Note: declare the process cap **only** under `deploy.resources.limits.pids`. Setting the
> top-level `pids_limit` as well makes Compose fail validation with
> `can't set distinct values on 'pids_limit' and 'deploy.resources.limits.pids'`, because it
> reads the absent `deploy` value as 0.

but it only works when Docker's storage driver can enforce a per-container quota, meaning
**overlay2 on XFS mounted with `pquota`**, or `btrfs`/`devicemapper`. On Docker Desktop
(Windows/macOS) the backing filesystem inside the VM is ext4, and Docker rejects the option
with `--storage-opt is supported only for overlay over xfs with 'pquota' mount option`,
which prevents the container from starting. Setting it by default would break the stack for
most users, so it ships commented out next to `k8s-api-server` in `docker-compose.yaml`.

What to do instead, depending on host:

- **Docker Desktop (Windows/macOS)** - the effective cap is the Docker Desktop disk image
  size: Settings > Resources > Disk image size. Everything Docker does lives inside that
  virtual disk, so it bounds the whole stack against your real drive. This is the setting
  that actually protects your 1 TB drive. Reclaim space with `docker system prune -af`
  and `docker volume prune`.
- **Linux host with XFP/pquota** - uncomment the `storage_opt` block; it is the real
  per-container quota.
- **Any host** - the log caps above are already applied, which removes the most common
  slow disk-filling vector.

Note that the container's writable layer is where a `dd if=/dev/zero of=/big` inside a lab
would land. Under Docker Desktop that fills the VM disk image, not your `D:` drive
directly, but the image file itself grows on the host, so the Docker Desktop disk cap is
the boundary that counts.

## What is deliberately still permissive

- `k8s-api-server` and `jumphost` run **privileged**. They have to: one runs
  docker-in-docker to host the k3d cluster, the other drives environment setup. Privileged
  means a determined attacker inside them can reach the host. This is a local practice tool
  and the threat model is *your own mistakes*, not a hostile tenant. Do not expose this
  stack to untrusted users or to a public network.
- Only nginx publishes a host port (`30080`). Everything else is reachable only on the
  internal compose network.
