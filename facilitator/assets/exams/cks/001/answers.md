# CKS Practice Lab - Kubernetes Security Essentials

## Question 1: Network Policies for Backend Services

Create a NetworkPolicy that restricts access to backend pods and controls their egress:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: secure-backend
  namespace: network-security
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```

This NetworkPolicy ensures:
- Only pods with label `app=frontend` can access backend pods on port 8080
- Backend pods can only communicate with pods labeled `app=database` on port 5432

## Question 2: TLS-Enabled Ingress

Create an Ingress resource with TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-app
  namespace: secure-ingress
spec:
  tls:
  - hosts:
    - secure-app.example.com
    secretName: secure-app-tls
  rules:
  - host: secure-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

This Ingress:
- Routes traffic for hostname `secure-app.example.com` to the `web-service` service
- Uses the pre-created `secure-app-tls` secret for TLS termination

## Question 3: API Security with Pod Security Standards

Create a namespace with Pod Security Standard:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: api-security
  labels:
    pod-security.kubernetes.io/enforce: baseline
```

Create a secure pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: api-security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: nginx
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
```

Create Role and RoleBinding for PSS viewing:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pss-viewer-role
  namespace: api-security
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["namespaces/status"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pss-viewer-binding
  namespace: api-security
subjects:
- kind: ServiceAccount
  name: pss-viewer
  namespace: api-security
roleRef:
  kind: Role
  name: pss-viewer-role
  apiGroup: rbac.authorization.k8s.io
```

This implementation:
- Creates a namespace with the Pod Security Standard "baseline" enforcement
- Deploys a pod that complies with the baseline standard (non-root, no privilege escalation)
- Sets up RBAC permissions for the PSS viewer service account

## Question 4: Node Metadata Protection

Create a NetworkPolicy to block metadata access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-metadata
  namespace: metadata-protect
spec:
  podSelector: {}  # Apply to all pods
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
```

Create a test pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: metadata-protect
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
```

## Question 5: Binary Verification

Create a pod to verify Kubernetes binaries:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: verify-bin
  namespace: binary-verify
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - |
      sha256sum /host-bin/kubectl >> /tmp/verified-hashes.txt
      sha256sum /host-bin/kubelet >> /tmp/verified-hashes.txt
      sleep 3600
    volumeMounts:
    - name: host-bin
      mountPath: /host-bin
      readOnly: true
  volumes:
  - name: host-bin
    hostPath:
      path: /usr/bin
      type: Directory
```

## Question 6: RBAC with Minimal Permissions

Create Role and RoleBinding for minimal access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-reader-role
  namespace: rbac-minimize
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-reader-binding
  namespace: rbac-minimize
subjects:
- kind: ServiceAccount
  name: app-reader
  namespace: rbac-minimize
roleRef:
  kind: Role
  name: app-reader-role
  apiGroup: rbac.authorization.k8s.io
```

## Question 7: Service Account Caution

Create ServiceAccount with disabled automounting:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: minimal-sa
  namespace: service-account-caution
automountServiceAccountToken: false
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: service-account-caution
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      serviceAccountName: minimal-sa
      automountServiceAccountToken: false
      containers:
      - name: nginx
        image: nginx
```

## Question 8: API Server Access Restriction

Create NetworkPolicy and test pods:

```bash
API_SERVER_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}')
```

```yaml
cat <<EOF > api-server-policy.yaml
# 1. Deny access to API server for all pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-server-policy
  namespace: api-restrict
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - ${API_SERVER_IP}/32

---
# 2. Allow access to API server for pods with label role=admin
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-admin-api-egress
  namespace: api-restrict
spec:
  podSelector:
    matchLabels:
      role: admin
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: ${API_SERVER_IP}/32
    ports:
    - protocol: TCP
      port: 443

---
# admin-pod (can access API server)
apiVersion: v1
kind: Pod
metadata:
  name: admin-pod
  namespace: api-restrict
  labels:
    role: admin
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]

---
# restricted-pod (blocked from API server)
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
  namespace: api-restrict
  labels:
    role: restricted
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
EOF
```

```bash
kubectl apply -f api-server-policy.yaml
```

## Question 9: Secure Container Configuration

Create a pod with minimal security context:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-container
  namespace: os-hardening
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
      readOnlyRootFilesystem: true
      runAsUser: 1000
      runAsGroup: 3000
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-cache-nginx
      mountPath: /var/cache/nginx
    - name: var-run
      mountPath: /var/run
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-cache-nginx
    emptyDir: {}
  - name: var-run
    emptyDir: {}
```

## Question 10: Seccomp Profile

Create a pod with seccomp and a sample profile:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
  namespace: seccomp-profile
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: seccomp-config
  namespace: seccomp-profile
data:
  profile.json: |
    {
      "defaultAction": "SCMP_ACT_ERRNO",
      "architectures": ["SCMP_ARCH_X86_64"],
      "syscalls": [
        {
          "names": ["exit", "exit_group", "rt_sigreturn", "read", "write", "open"],
          "action": "SCMP_ACT_ALLOW"
        }
      ]
    }
```

## Question 11: Pod Security Standards

Apply Pod Security Standards:

```bash
# Label the namespace
kubectl label namespace pod-security pod-security.kubernetes.io/enforce=baseline
```

Create a compliant pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: pod-security
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: nginx
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
```

Try to create a non-compliant pod and document the error:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-compliant-pod
  namespace: pod-security
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true
```

## Question 12: Secrets Management

Create and use secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
  namespace: secrets-management
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded 'admin'
  password: U2VjcmV0UEBzc3cwcmQ=  # base64 encoded 'SecretP@ssw0rd'
---
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: secrets-management
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/db-creds
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-creds
---
apiVersion: v1
kind: Pod
metadata:
  name: env-app
  namespace: secrets-management
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-creds
          key: password
```

