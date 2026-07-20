#!/bin/sh

# ===============================================================================
#   KIND/K3D Cluster Setup Entrypoint Script
#   Purpose: Initialize Docker Daemon, Provision Cluster, and Manage SSH Setup
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | ===== INITIALIZATION STARTED ====="
echo "$(date '+%Y-%m-%d %H:%M:%S') | Executing container startup script..."

if [ -f /usr/local/bin/startup.sh ]; then
    sh /usr/local/bin/startup.sh &
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Default startup script not found at /usr/local/bin/startup.sh"
fi

# ===============================================================================
#   Docker Daemon Readiness Verification
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | Checking Docker service status..."
DOCKER_CHECK_COUNT=0

while ! docker ps >/dev/null 2>&1; do
    DOCKER_CHECK_COUNT=$((DOCKER_CHECK_COUNT+1))
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [WAITING] Docker service not ready yet... (attempt $DOCKER_CHECK_COUNT)"
    sleep 5
done

echo "$(date '+%Y-%m-%d %H:%M:%S') | [SUCCESS] Docker service is ready and operational"

adduser -S -D -H -s /sbin/nologin -G sshd sshd
/usr/sbin/sshd -D &

# ===============================================================================
#   K3D Installation & Cluster Topology Provisioning
# ===============================================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Installing k3d binary..."
TAG=v5.8.3 bash /usr/local/bin/k3d-install.sh

# Replace the env-setup block at the bottom of .\kind-cluster\entrypoint.sh with this:
if [ -f /usr/local/bin/env-setup ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Executing K3D cluster orchestration..."
    bash /usr/local/bin/env-setup

    echo "$(date '+%Y-%m-%d %H:%M:%S') | [INFO] Provisioning kubeconfig structure for candidate..."
    mkdir -p /home/candidate/.kube
    
    # Export to the exact filename format the jumphost configuration requires
    /usr/local/bin/k3d kubeconfig get cluster > /home/candidate/.kube/kubeconfig
    sed -i 's/127.0.0.1/k8s-api-server/g' /home/candidate/.kube/kubeconfig
    
    # Create a duplicate fallback reference to satisfy local binary contexts
    cp /home/candidate/.kube/kubeconfig /home/candidate/.kube/config
    
    chown -R candidate: /home/candidate/.kube
    chmod 600 /home/candidate/.kube/config /home/candidate/.kube/kubeconfig

    echo "$(date '+%Y-%m-%d %H:%M:%S') | [SUCCESS] Kubernetes backend initialized successfully."
    touch /ready
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') | [ERROR] /usr/local/bin/env-setup script missing!"
    touch /ready
fi
exec tail -f /dev/null