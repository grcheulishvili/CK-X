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
