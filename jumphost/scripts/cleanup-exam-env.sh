#!/bin/bash
exec >> /proc/1/fd/1 2>&1

# cleanup-exam-env.sh
#
# Resets the exam machine to a pristine state after a session ends.
#
# The candidate works on THIS host, so anything they created here survives unless
# it is removed explicitly: generated manifests in their home directory, files the
# questions ask them to write under /tmp and /etc, images and containers built in
# the Docker labs, and Helm repositories added to their profile. Leaving any of it
# behind lets one session's leftovers satisfy the next session's checks.
#
# Cluster-side state does not need handling here: env-cleanup deletes the k3d
# cluster outright, which takes every Kubernetes object with it.

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting exam environment cleanup"

# ---------------------------------------------------------------- cluster ----
log "Cleaning up cluster $CLUSTER_NAME"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    candidate@k8s-api-server "env-cleanup $CLUSTER_NAME"

# ---------------------------------------------------------------- docker -----
# Remove running containers first. `docker system prune` only reclaims stopped
# ones, so a container started in a Docker lab would otherwise still be running
# for the next candidate.
log "Removing containers from Docker labs"
RUNNING=$(docker ps -aq 2>/dev/null)
if [ -n "$RUNNING" ]; then
  docker rm -f $RUNNING >/dev/null 2>&1 || true
fi

log "Cleaning up docker environment"
docker system prune -a --volumes -f >/dev/null 2>&1 || true
docker network prune -f >/dev/null 2>&1 || true
docker volume prune -f >/dev/null 2>&1 || true

# Restore the daemon config, which one of the Docker questions edits.
log "Restoring /etc/docker/daemon.json"
echo '{ "exec-opts": ["native.cgroupdriver=cgroupfs"] }' > /etc/docker/daemon.json

# ------------------------------------------------------------ candidate ------
# Wipe everything the candidate created in their home directory, keeping only the
# shell profile and the ssh/kube directories the environment depends on.
log "Resetting /home/candidate"
find /home/candidate -mindepth 1 -maxdepth 1 \
     ! -name '.bashrc' ! -name '.bash_profile' ! -name '.profile' \
     ! -name '.ssh' ! -name '.kube' \
     -exec rm -rf {} + 2>/dev/null || true

# Helm repositories, plugins and caches live outside the home root on some
# layouts, and kubectl keeps a discovery cache that points at the deleted cluster.
rm -rf /home/candidate/.kube/cache /home/candidate/.kube/http-cache 2>/dev/null || true
rm -rf /home/candidate/.config/helm /home/candidate/.cache/helm \
       /home/candidate/.local/share/helm /home/candidate/.helm 2>/dev/null || true
rm -rf /root/.config/helm /root/.cache/helm /root/.kube/cache 2>/dev/null || true
chown -R candidate: /home/candidate 2>/dev/null || true

# ------------------------------------------------------------- artefacts -----
# Paths the questions themselves tell candidates to write to.
log "Removing exam artefacts"
rm -rf /tmp/exam-env /tmp/exam /tmp/exam-assets
rm -rf /root/oci-images
rm -rf /etc/kubernetes/manifests
rm -f  /tmp/Dockerfile /tmp/index.html /tmp/k3d-config.yaml
rm -f  /tmp/verified-hashes.txt /tmp/violation.txt /tmp/release-notes.txt \
       /tmp/pod-images.txt /tmp/all-container-images.txt /tmp/dns-test.txt \
       /tmp/etcd-backup.db
# Any manifest left at the top level of /tmp by a generate-then-edit workflow.
find /tmp -maxdepth 1 -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) \
     -delete 2>/dev/null || true

log "Exam environment cleanup completed successfully"
exit 0
