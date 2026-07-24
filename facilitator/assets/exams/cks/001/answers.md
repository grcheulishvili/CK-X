# CKS Assessment 01 - Solutions (imperative-first)

`export do='--dry-run=client -o yaml'`. Use imperative for namespaces, PSA labels, RBAC,
secrets; concise YAML for NetworkPolicy / securityContext / Ingress-TLS (no generators).

---

## Q1 - NetworkPolicy: backend ingress + egress
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: secure-backend, namespace: network-security}
spec:
  podSelector: {matchLabels: {app: backend}}
  policyTypes: ["Ingress","Egress"]
  ingress:
  - from: [{podSelector: {matchLabels: {app: frontend}}}]
    ports: [{protocol: TCP, port: 8080}]
  egress:
  - to: [{podSelector: {matchLabels: {app: database}}}]
    ports: [{protocol: TCP, port: 5432}]
EOF
```

## Q2 - TLS Ingress
```bash
kubectl create ingress secure-app -n secure-ingress \
  --rule="secure-app.example.com/*=web-service:80,tls=secure-app-tls"
kubectl get ingress secure-app -n secure-ingress -o yaml   # confirm spec.tls + rules
```

## Q3 - PSA baseline + compliant pod + RBAC to view PSS labels
```bash
kubectl create namespace api-security
kubectl label namespace api-security pod-security.kubernetes.io/enforce=baseline
kubectl run secure-pod -n api-security --image=nginx     # nginx meets 'baseline' as-is
# pss-viewer needs to read namespace labels -> get/list namespaces (cluster-scoped resource)
kubectl create clusterrole ns-viewer --verb=get,list --resource=namespaces
kubectl create clusterrolebinding pss-viewer-binding \
  --clusterrole=ns-viewer --serviceaccount=api-security:pss-viewer
```

## Q4 - Block node-metadata egress
```bash
kubectl run test-pod -n metadata-protect --image=busybox -- sleep 3600
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: block-metadata, namespace: metadata-protect}
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except: ["169.254.169.254/32"]
EOF
```

## Q5 - Read-only hostPath + hash host binaries
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: verify-bin, namespace: binary-verify}
spec:
  volumes: [{name: hostbin, hostPath: {path: /usr/bin}}]
  containers:
  - name: verify
    image: busybox
    command: ["sh","-c","sha256sum /host-bin/kubectl >> /tmp/verified-hashes.txt; sha256sum /host-bin/kubelet >> /tmp/verified-hashes.txt; sleep 3600"]
    volumeMounts: [{name: hostbin, mountPath: /host-bin, readOnly: true}]
EOF
```

## Q6 - Least-privilege Role (no secrets/configmaps)
```bash
kubectl create role app-reader-role -n rbac-minimize \
  --verb=get,list,watch --resource=pods,services,deployments
kubectl create rolebinding app-reader-binding -n rbac-minimize \
  --role=app-reader-role --serviceaccount=rbac-minimize:app-reader
# confirm the negative: secrets must NOT be readable
kubectl auth can-i get secrets --as=system:serviceaccount:rbac-minimize:app-reader -n rbac-minimize   # no
```

## Q7 - Deployment with token automount disabled
```bash
kubectl create serviceaccount minimal-sa -n service-account-caution
kubectl patch serviceaccount minimal-sa -n service-account-caution -p '{"automountServiceAccountToken":false}'
kubectl create deployment secure-app -n service-account-caution --image=nginx --replicas=2 $do > d.yaml
# set spec.template.spec.serviceAccountName: minimal-sa and automountServiceAccountToken: false
kubectl apply -f d.yaml
```
Pod-template fields to add under `spec.template.spec`:
```yaml
      serviceAccountName: minimal-sa
      automountServiceAccountToken: false
```

## Q8 - Restrict egress to API server (allow only role=admin)
```bash
kubectl run admin-pod -n api-restrict --image=busybox --labels=role=admin -- sleep 3600
kubectl run restricted-pod -n api-restrict --image=busybox --labels=role=restricted -- sleep 3600
# deny egress to the apiserver for everyone, then allow it back for role=admin.
# find the apiserver ClusterIP: kubectl get svc kubernetes -n default (usually 10.43.0.1 on k3s)
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: api-server-policy, namespace: api-restrict}
spec:
  podSelector: {matchLabels: {role: admin}}
  policyTypes: ["Egress"]
  egress:
  - to: [{ipBlock: {cidr: 10.43.0.1/32}}]
    ports: [{protocol: TCP, port: 443}]
EOF
```
> Selecting only `role=admin` leaves `restricted-pod` unselected (all egress allowed) - for a
> true deny you'd add a default-deny-egress selecting `{}` and this allow for admin.

## Q9 - Hardened container (caps, read-only FS, uid/gid)
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: secure-container, namespace: os-hardening}
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsUser: 1000
      runAsGroup: 3000
      readOnlyRootFilesystem: true
      capabilities: {drop: ["ALL"], add: ["NET_BIND_SERVICE"]}
    volumeMounts:
    - {name: tmp, mountPath: /tmp}
    - {name: cache, mountPath: /var/cache/nginx}
    - {name: run, mountPath: /var/run}
  volumes:
  - {name: tmp, emptyDir: {}}
  - {name: cache, emptyDir: {}}
  - {name: run, emptyDir: {}}
EOF
```
> nginx needs writable `/var/cache/nginx`, `/var/run`, `/tmp`; with a read-only rootfs those
> must be emptyDir mounts or the container crashes.

## Q10 - Seccomp RuntimeDefault + profile ConfigMap
```bash
kubectl create configmap seccomp-config -n seccomp-profile --from-file=profile.json=/dev/stdin <<'JSON'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {"names": ["exit","exit_group","rt_sigreturn","read","write","open"], "action": "SCMP_ACT_ALLOW"}
  ]
}
JSON
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: seccomp-pod, namespace: seccomp-profile}
spec:
  securityContext:
    seccompProfile: {type: RuntimeDefault}
  containers: [{name: nginx, image: nginx}]
EOF
```

## Q11 - PSA baseline: compliant vs violating pod
```bash
kubectl label namespace pod-security pod-security.kubernetes.io/enforce=baseline
kubectl run compliant-pod -n pod-security --image=nginx     # allowed
# the violating pod is rejected by the admission controller; capture the error:
kubectl run non-compliant-pod -n pod-security --image=nginx \
  --overrides='{"spec":{"containers":[{"name":"c","image":"nginx","securityContext":{"privileged":true,"runAsUser":0}}]}}' \
  2> /tmp/violation.txt || cat /tmp/violation.txt
```

## Q12 - Secret as files + as env vars
```bash
kubectl create secret generic db-creds -n secrets-management \
  --from-literal=username=admin --from-literal=password='SecretP@ssw0rd'
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: secure-app, namespace: secrets-management}
spec:
  volumes: [{name: creds, secret: {secretName: db-creds}}]
  containers:
  - {name: app, image: busybox, command: ["sleep","3600"], volumeMounts: [{name: creds, mountPath: /etc/db-creds}]}
---
apiVersion: v1
kind: Pod
metadata: {name: env-app, namespace: secrets-management}
spec:
  containers:
  - name: app
    image: busybox
    command: ["sleep","3600"]
    env:
    - {name: DB_USER, valueFrom: {secretKeyRef: {name: db-creds, key: username}}}
    - {name: DB_PASS, valueFrom: {secretKeyRef: {name: db-creds, key: password}}}
EOF
```
