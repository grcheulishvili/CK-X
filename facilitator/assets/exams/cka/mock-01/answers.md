# Mock Exam 01 Solutions

## Question 1: Pod Deployment Troubleshooting

```bash
kubectl create configmap app-config --from-literal=database_host=postgres.production.svc.cluster.local -n production

kubectl patch pod app-frontend -n production -p '{"spec":{"volumes":[{"name":"config-vol","configMap":{"name":"app-config"}}],"containers":[{"name":"app","volumeMounts":[{"name":"config-vol","mountPath":"/etc/app/config.yaml","subPath":"config.yaml"}]}]}}'
```

## Question 2: RBAC and Service Account

```bash
kubectl create role dev-role --verb=list --resource=pods,deployments -n staging
kubectl create rolebinding dev-binding --role=dev-role --user=dev-user -n staging
```

## Question 3: Node Maintenance

```bash
kubectl drain k3d-cluster-agent-0 --ignore-daemonsets
```

## Question 4: Persistent Volume Configuration

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: db-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fast-ssd
  hostPath:
    path: /data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
  namespace: databases
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  resources:
    requests:
      storage: 5Gi
  storageClassName: fast-ssd
```

## Question 5: Network Policy Troubleshooting

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: shop
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              tier: frontend
      ports:
        - protocol: TCP
          port: 3000
```

## Question 6

```bash
kubectl label node k3d-cluster-agent-0 disktype=ssd
kubectl run ssd-pod --image=nginx --overrides='{"spec":{"nodeSelector":{"disktype":"ssd"}}}'
```

## Question 7

```bash
kubectl -n web create deployment web --image=nginx:1.25 --replicas=3
kubectl -n web scale deployment web --replicas=5
kubectl -n web set image deployment/web nginx=nginx:1.26
kubectl -n web rollout status deployment/web
```

## Question 8

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "200m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
```

## Question 9

```bash
kubectl -n web expose deployment web --name=web-svc --port=80 --target-port=80 --type=ClusterIP
```

## Question 10

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: web
spec:
  rules:
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
```

## Question 11

```bash
# container name equals the deployment name when created with 'kubectl create deployment'
kubectl set image deployment/broken-app broken-app=nginx:1.25
kubectl rollout status deployment/broken-app
```

## Question 12

```bash
kubectl create cronjob backup --image=busybox --schedule='*/5 * * * *' -- date
```

## Question 13

```bash
# the deployment labels its pods app=api
kubectl -n store patch svc api-svc -p '{"spec":{"selector":{"app":"api"}}}'
kubectl -n store get endpoints api-svc
```

## Question 14

```bash
# the 200-core CPU request cannot be satisfied; recreate with a sane request
kubectl delete pod pending-pod
kubectl run pending-pod --image=nginx --requests='cpu=100m'
# (or: kubectl get pod pending-pod -o yaml > p.yaml; edit requests; kubectl replace --force -f p.yaml)
```

## Question 15

```bash
kubectl delete pod crash-pod
kubectl run crash-pod --image=busybox -- sh -c 'sleep 3600'
```

## Question 16

```bash
# the claim asks for 1Gi but the only matching PV is 100Mi.
# Option A: recreate the claim requesting <=100Mi
kubectl delete pvc app-pvc
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: app-pvc}
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual
  resources: {requests: {storage: 100Mi}}
YAML
# Option B: enlarge the PV to 1Gi and let it bind.
```

## Question 17

```bash
mkdir -p /tmp/exam
cat > /tmp/exam/q17_etcd_restore.txt <<'CMD'
ETCDCTL_API=3 etcdctl snapshot restore /opt/backup.db \
  --data-dir=/var/lib/etcd-restored
CMD
```
