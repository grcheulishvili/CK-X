# CKAD Assessment 01 - Solutions (imperative-first)

`export do='--dry-run=client -o yaml'`. Use imperative generators; generate-then-edit for
anything without one (PV/PVC/SC, multi-container pods, probes, secrets-as-env-mapping, CRD).

---

## Q1 - Deployment in a namespace
```bash
kubectl create namespace dev
kubectl create deployment nginx-deployment -n dev --image=nginx:latest --replicas=3
```

## Q2 - PersistentVolume (hostPath, Retain)
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata: {name: pv-storage}
spec:
  capacity: {storage: 1Gi}
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  hostPath: {path: /mnt/data}
EOF
```

## Q3 - StorageClass (no-provisioner, WaitForFirstConsumer)
```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: {name: fast-storage}
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

## Q4 - PVC using that StorageClass
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: pvc-app, namespace: storage-test}
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: fast-storage
  resources: {requests: {storage: 500Mi}}
EOF
```

## Q5 - Troubleshoot `broken-app`
**Workflow:** read state -> find the cause -> fix the field.
```bash
kubectl -n troubleshooting get pods
kubectl -n troubleshooting describe deploy broken-app        # Events / image / resources
kubectl -n troubleshooting describe pod <pod>                # ImagePullBackOff? CrashLoop? OOM?
kubectl -n troubleshooting logs <pod> --previous
```
Then fix the specific fault, e.g. a bad image tag:
```bash
kubectl -n troubleshooting set image deploy/broken-app <container>=nginx:1.25
kubectl -n troubleshooting rollout status deploy/broken-app
```
(If it's a resources/probe fault instead, `kubectl -n troubleshooting edit deploy broken-app` and correct that field.)

## Q6 - Sidecar pod (shared emptyDir)
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: sidecar-pod, namespace: troubleshooting}
spec:
  volumes: [{name: log-volume, emptyDir: {}}]
  containers:
  - {name: nginx, image: nginx, volumeMounts: [{name: log-volume, mountPath: /var/my-log}]}
  - name: sidecar
    image: busybox
    command: ["sh","-c","while true; do date >> /var/my-log/date.log; sleep 10; done"]
    volumeMounts: [{name: log-volume, mountPath: /var/my-log}]
EOF
```

## Q7 - Troubleshoot Service `web-service`
```bash
kubectl -n troubleshooting get svc web-service -o wide
kubectl -n troubleshooting get endpoints web-service        # empty => selector/port wrong
kubectl -n troubleshooting get pods --show-labels
# fix the selector to match the pod labels (and targetPort to the container port)
kubectl -n troubleshooting patch svc web-service -p '{"spec":{"selector":{"app":"<pod-label>"}}}'
kubectl -n troubleshooting get endpoints web-service        # now populated
```

## Q8 - Cap CPU/memory on the hot container in `logging-pod`
```bash
kubectl -n troubleshooting top pod logging-pod --containers   # find the greedy container
kubectl -n troubleshooting get pod logging-pod -o yaml > lp.yaml
# add to that container: resources.limits {cpu: 100m, memory: 50Mi}
kubectl -n troubleshooting replace --force -f lp.yaml         # pods are immutable -> recreate
```

## Q9 - ConfigMap + pod env + resources
```bash
kubectl create configmap app-config -n workloads \
  --from-literal=APP_ENV=production --from-literal=LOG_LEVEL=info
kubectl run config-pod -n workloads --image=nginx $do > config-pod.yaml
```
Add `envFrom` + `resources`, then apply:
```yaml
    envFrom: [{configMapRef: {name: app-config}}]
    resources:
      requests: {cpu: 100m, memory: 128Mi}
      limits:   {cpu: 200m, memory: 256Mi}
```

## Q10 - Secret + MySQL pod (env key remap)
```bash
kubectl create secret generic db-credentials -n workloads \
  --from-literal=username=admin --from-literal=random=true --from-literal=password=securepass
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: secure-pod, namespace: workloads}
spec:
  containers:
  - name: mysql
    image: mysql:9.5.0
    env:
    - {name: DB_USER,                    valueFrom: {secretKeyRef: {name: db-credentials, key: username}}}
    - {name: MYSQL_RANDOM_ROOT_PASSWORD, valueFrom: {secretKeyRef: {name: db-credentials, key: random}}}
    - {name: DB_PASSWORD,                valueFrom: {secretKeyRef: {name: db-credentials, key: password}}}
EOF
```

## Q11 - CronJob (hourly, Forbid, history limits)
```bash
kubectl create cronjob log-cleaner -n workloads --image=busybox --schedule="0 * * * *" \
  -- find /var/log -type f -name "*.log" -mtime +7 -delete
kubectl -n workloads patch cronjob log-cleaner -p \
  '{"spec":{"concurrencyPolicy":"Forbid","successfulJobsHistoryLimit":3,"failedJobsHistoryLimit":1}}'
```

## Q12 - Pod with liveness (HTTP) + readiness (TCP) probes
```bash
kubectl run health-pod -n workloads --image=emilevauge/whoami $do > health-pod.yaml
```
Add to the container, then apply:
```yaml
    livenessProbe:
      httpGet: {path: /healthz, port: 80}
      periodSeconds: 15
      initialDelaySeconds: 5
      timeoutSeconds: 1
      failureThreshold: 3
    readinessProbe:
      tcpSocket: {port: 80}
      periodSeconds: 10
      initialDelaySeconds: 5
```

## Q13 - ClusterRole + ClusterRoleBinding for user `jane`
```bash
kubectl create clusterrole pod-reader --verb=get,watch,list --resource=pods
kubectl create clusterrolebinding read-pods --clusterrole=pod-reader --user=jane
kubectl auth can-i list pods --as=jane -A
```

## Q14 - Helm: Bitnami nginx, 2 replicas
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create namespace web
helm install nginx bitnami/nginx -n web --set replicaCount=2
kubectl get pods,svc -n web
```

## Q15 - CustomResourceDefinition
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata: {name: backups.data.example.com}
spec:
  group: data.example.com
  scope: Namespaced
  names: {plural: backups, singular: backup, kind: Backup, shortNames: [bk]}
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: [source, destination]
            properties:
              source:      {type: string}
              destination: {type: string}
EOF
```

## Q16 - NetworkPolicy (frontend -> web:80)
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-traffic, namespace: networking}
spec:
  podSelector: {matchLabels: {app: web}}
  policyTypes: ["Ingress"]
  ingress:
  - from: [{podSelector: {matchLabels: {tier: frontend}}}]
    ports: [{protocol: TCP, port: 80}]
EOF
```

## Q17 - ClusterIP service (80 -> 8080, selects app=backend)
```bash
kubectl create service clusterip internal-app -n networking --tcp=80:8080 $do > svc.yaml
# the generator sets selector app=internal-app; change it to app=backend, then apply
sed -i 's/app: internal-app/app: backend/' svc.yaml
kubectl apply -f svc.yaml
```

## Q18 - NodePort service (80 -> 8080, nodePort 30080)
```bash
kubectl expose deployment web-frontend -n networking --name=public-web \
  --port=80 --target-port=8080 --type=NodePort $do > public-web.yaml
# set ports[0].nodePort: 30080
kubectl apply -f public-web.yaml
```

## Q19 - Ingress (host-based)
```bash
kubectl create ingress api-ingress -n networking \
  --rule="api.example.com/*=api-service:80"
```

## Q20 - Job (run once, deadline 30s, restartPolicy Never)
```bash
kubectl create job hello-job -n networking --image=busybox \
  -- sh -c "echo 'Hello from Kubernetes job!'"
kubectl -n networking patch job hello-job -p '{"spec":{"activeDeadlineSeconds":30}}'
# kubectl create job already sets restartPolicy: Never
```

## Q21 - Export image in OCI format
```bash
docker pull nginx:latest
mkdir -p /root/oci-images
# Docker archive (portable tarball):
docker save nginx:latest -o /root/oci-images/nginx.tar
# True OCI layout (if skopeo is available):
skopeo copy docker-daemon:nginx:latest oci:/root/oci-images/nginx:latest
```
