# CKA Assessment 01 — Solutions (imperative-first)

These solutions use the **real exam workflow**: reach for an imperative `kubectl` command
first, and only drop to YAML when a resource has no generator (StorageClass, PVC,
NetworkPolicy, multi-container pods, probes, affinity). The fast pattern for "YAML-only"
resources is to *generate* a skeleton and edit it, not to type YAML from memory:

```bash
alias k=kubectl
export do='--dry-run=client -o yaml'   # k run x --image=nginx $do > x.yaml
```

---

## Question 1 — Pod in a namespace with a label

**Approach:** fully imperative.

```bash
kubectl create namespace app-team1
kubectl run nginx-pod --image=nginx:1.19 -n app-team1 --labels=run=nginx-pod
# verify
kubectl get pod nginx-pod -n app-team1 -o wide
```

---

## Question 2 - Static pod manifest

**Approach:** generate the manifest imperatively, then write it to the static-pod directory.

```bash
kubectl run static-web --image=nginx:1.19 --port=80 \
  --dry-run=client -o yaml > /etc/kubernetes/manifests/static-web.yaml
cat /etc/kubernetes/manifests/static-web.yaml
```

On a real kubeadm node the kubelet picks this up within seconds and the running pod is named
`static-web-<nodename>`; check with `kubectl get pods`. In this lab nothing watches the path,
so the manifest itself is what is graded. The exam skill is knowing the directory and that
`--dry-run=client -o yaml` writes the manifest for you.

## Question 3 — StorageClass + PVC

**Approach:** no imperative generator exists for StorageClass or PVC, so apply a small YAML.
Keep this skeleton bookmarked — you'll reuse it every exam.

```bash
kubectl create namespace storage
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: fast-storage
  resources:
    requests:
      storage: 1Gi
EOF
# verify (PVC stays Pending until a pod consumes it — WaitForFirstConsumer)
kubectl get sc fast-storage; kubectl get pvc -n storage
```

---

## Question 4 — Multi-container pod sharing an emptyDir

**Approach:** `kubectl run` only makes single-container pods, so generate one container, then
edit in the second container and the shared volume.

```bash
kubectl run logger -n monitoring --image=busybox $do \
  -- sh -c 'while true; do echo "$(date) log line" >> /var/log/app.log; sleep 5; done' > logger.yaml
```

Edit `logger.yaml` so both containers mount the same `emptyDir`:

```yaml
spec:
  volumes:
  - name: log-volume
    emptyDir: {}
  containers:
  - name: logger            # the busybox writer generated above
    image: busybox
    command: ["sh","-c","while true; do echo \"$(date) log line\" >> /var/log/app.log; sleep 5; done"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
  - name: fluentd
    image: fluentd
    volumeMounts:
    - name: log-volume
      mountPath: /var/log
```

```bash
kubectl apply -f logger.yaml
kubectl get pod logger -n monitoring
```

---

## Question 5 — RBAC (ServiceAccount + Role + RoleBinding)

**Approach:** fully imperative — the `kubectl create role/rolebinding` generators are faster
and less error-prone than writing the RBAC YAML by hand.

```bash
kubectl create serviceaccount app-sa
kubectl create role pod-reader --verb=get,list --resource=pods
kubectl create rolebinding read-pods --role=pod-reader --serviceaccount=default:app-sa
# verify the binding actually grants the permission
kubectl auth can-i list pods --as=system:serviceaccount:default:app-sa
```

---

## Question 6 — NetworkPolicy (allow one label, deny the rest)

**Approach:** NetworkPolicy has no generator → YAML. Selecting `role=db` for Ingress with a
single `from` allowing `role=frontend` implicitly denies all other ingress to `role=db`.

```bash
kubectl create namespace networking
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: networking
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 3306
EOF
```

> This lab's CNI (flannel) doesn't enforce NetworkPolicy, so it's graded on the spec. On the
> real exam the CNI enforces it — test with a temporary pod:
> `kubectl run t --rm -it --image=busybox -- wget -qO- <db-ip>:3306`.

---

## Question 7 - Deployment + NodePort + pod anti-affinity

**Approach:** create the Deployment and Service imperatively; add anti-affinity by editing the
Deployment (there is no flag for it).

```bash
kubectl create deployment web-app --image=nginx:1.19 --replicas=3
kubectl expose deployment web-app --name=web-service --port=80 --target-port=80 --type=NodePort
kubectl edit deployment web-app     # add the affinity block below under spec.template.spec
```

```yaml
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: web-app
              topologyKey: kubernetes.io/hostname
```

```bash
kubectl rollout status deployment/web-app
kubectl get pods -l app=web-app -o wide   # spread across nodes, all Running
```

**Why preferred, not required:** a `required` rule with `topologyKey: kubernetes.io/hostname`
allows at most one replica per node. This cluster has 3 schedulable nodes, so 3 replicas fit -
but the moment replicas exceed node count the extras stay `Pending` forever and the deployment
never becomes fully available. `preferred` still spreads the pods but degrades gracefully.
Knowing that difference is the actual exam skill here.

---

## Question 8 — Pod with resource requests/limits

**Approach:** generate, then add the resources block (`kubectl run` can't express both
requests and limits cleanly).

```bash
kubectl run resource-pod -n monitoring --image=nginx $do > resource-pod.yaml
```

Add under the container:

```yaml
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
```

```bash
kubectl apply -f resource-pod.yaml
kubectl get pod resource-pod -n monitoring
```

---

## Question 9 — ConfigMap mounted as a volume

**Approach:** ConfigMap imperatively; mount it by editing a generated pod (volume mounts have
no flag).

```bash
kubectl create configmap app-config --from-literal=APP_COLOR=blue
kubectl run config-pod --image=nginx $do > config-pod.yaml
```

Add the volume + mount:

```yaml
spec:
  containers:
  - name: config-pod
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

```bash
kubectl apply -f config-pod.yaml
kubectl exec config-pod -- cat /etc/config/APP_COLOR   # -> blue
```

---

## Question 10 — Liveness and readiness probes

**Approach:** generate, then add both probes.

```bash
kubectl run health-check --image=nginx $do > health-check.yaml
```

Add under the container:

```yaml
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
```

```bash
kubectl apply -f health-check.yaml
kubectl get pod health-check          # READY 1/1 once the readiness probe passes
kubectl describe pod health-check | grep -A2 -i 'Liveness\|Readiness'
```
