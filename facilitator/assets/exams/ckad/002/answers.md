# CKAD Assessment 02 - Solutions (imperative-first)

`export do='--dry-run=client -o yaml'`. Imperative first; generate-then-edit for pods needing
volumes/probes/security/env-remap, and for PV/PVC/NetworkPolicy/CRD (no generators).

---

## Q1 - Namespace + labelled pod
```bash
kubectl create namespace core-concepts
kubectl run nginx-pod -n core-concepts --image=nginx --labels=app=web,env=prod
```

## Q2 - Multi-container pod (shared emptyDir)
```bash
kubectl create namespace multi-container
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: multi-container-pod, namespace: multi-container}
spec:
  volumes: [{name: log-volume, emptyDir: {}}]
  containers:
  - {name: main-container, image: nginx, volumeMounts: [{name: log-volume, mountPath: /var/log}]}
  - name: sidecar-container
    image: busybox
    command: ["sh","-c","while true; do echo \$(date) >> /var/log/app.log; sleep 5; done"]
    volumeMounts: [{name: log-volume, mountPath: /var/log}]
EOF
```

## Q3 - Deployment + ClusterIP service
```bash
kubectl create namespace pod-design
kubectl create deployment frontend -n pod-design --image=nginx:1.19.0 --replicas=3
kubectl label deployment frontend -n pod-design app=frontend tier=frontend --overwrite
kubectl patch deployment frontend -n pod-design -p \
  '{"spec":{"template":{"metadata":{"labels":{"app":"frontend","tier":"frontend"}}}}}'
kubectl expose deployment frontend -n pod-design --name=frontend-svc --port=80 --target-port=80 --type=ClusterIP
```

## Q4 - ConfigMap (env) + Secret (volume) + pod
```bash
kubectl create namespace configuration
kubectl create configmap app-config -n configuration \
  --from-literal=DB_HOST=mysql --from-literal=DB_PORT=3306 --from-literal=DB_NAME=myapp
kubectl create secret generic app-secret -n configuration \
  --from-literal=DB_USER=admin --from-literal=DB_PASSWORD=s3cr3t
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: app-pod, namespace: configuration}
spec:
  volumes: [{name: sec, secret: {secretName: app-secret}}]
  containers:
  - name: nginx
    image: nginx
    envFrom: [{configMapRef: {name: app-config}}]
    volumeMounts: [{name: sec, mountPath: /etc/app-secret}]
EOF
```

## Q5 - Probes + resources
```bash
kubectl create namespace observability
kubectl run probes-pod -n observability --image=nginx $do > p.yaml
```
Add to the container, then apply:
```yaml
    livenessProbe:  {httpGet: {path: /healthz, port: 80}, initialDelaySeconds: 10, periodSeconds: 5}
    readinessProbe: {httpGet: {path: /, port: 80}, initialDelaySeconds: 5, periodSeconds: 3}
    resources:
      requests: {cpu: 100m, memory: 128Mi}
      limits:   {cpu: 200m, memory: 256Mi}
```

## Q6 - Deployment + three service types
```bash
kubectl create namespace services
kubectl create deployment web-app -n services --image=nginx:alpine --replicas=3
kubectl patch deployment web-app -n services -p '{"spec":{"template":{"metadata":{"labels":{"app":"web"}}}}}'
kubectl label deployment web-app -n services app=web --overwrite
kubectl expose deployment web-app -n services --name=web-svc-cluster  --port=80 --type=ClusterIP
kubectl expose deployment web-app -n services --name=web-svc-lb       --port=80 --type=LoadBalancer
kubectl expose deployment web-app -n services --name=web-svc-nodeport --port=80 --type=NodePort $do > np.yaml
# set ports[0].nodePort: 30080, then apply
kubectl apply -f np.yaml
```

## Q7 - PV + PVC + MySQL pod
```bash
kubectl create namespace state
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata: {name: db-pv}
spec:
  capacity: {storage: 1Gi}
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  hostPath: {path: /mnt/data}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: db-pvc, namespace: state}
spec:
  accessModes: ["ReadWriteOnce"]
  resources: {requests: {storage: 500Mi}}
---
apiVersion: v1
kind: Pod
metadata: {name: db-pod, namespace: state}
spec:
  volumes: [{name: data, persistentVolumeClaim: {claimName: db-pvc}}]
  containers:
  - name: mysql
    image: mysql:5.7
    env:
    - {name: MYSQL_ROOT_PASSWORD, value: rootpassword}
    - {name: MYSQL_DATABASE, value: mydb}
    - {name: MYSQL_USER, value: myuser}
    - {name: MYSQL_PASSWORD, value: mypassword}
    volumeMounts: [{name: data, mountPath: /var/lib/mysql}]
EOF
```

## Q8 - CronJob (every 5 min, OnFailure, deadline)
```bash
kubectl create namespace pod-design 2>/dev/null
kubectl create cronjob backup-job -n pod-design --image=busybox --schedule="*/5 * * * *" \
  -- sh -c 'echo Backup started: $(date); sleep 30; echo Backup completed: $(date)'
kubectl -n pod-design patch cronjob backup-job -p \
  '{"spec":{"jobTemplate":{"spec":{"activeDeadlineSeconds":100,"template":{"spec":{"restartPolicy":"OnFailure"}}}}}}'
```

## Q9 - Troubleshoot `broken-deployment`
```bash
kubectl -n troubleshooting describe deploy broken-deployment
kubectl -n troubleshooting get pods
kubectl -n troubleshooting describe pod <pod>   # image? resources? Events
# common fix: correct the image tag
kubectl -n troubleshooting set image deploy/broken-deployment <container>=nginx:1.19
# if requests are impossibly high, lower them:
kubectl -n troubleshooting set resources deploy/broken-deployment --requests=cpu=100m,memory=128Mi
kubectl -n troubleshooting rollout status deploy/broken-deployment
```

## Q10 - NetworkPolicy (ingress + egress) + test pods
```bash
kubectl create namespace networking
kubectl run secure-db -n networking --image=postgres:12 --labels=app=db
kubectl run frontend  -n networking --image=nginx --labels=role=frontend
kubectl run monitoring -n networking --image=nginx --labels=role=monitoring
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: secure-db-policy, namespace: networking}
spec:
  podSelector: {matchLabels: {app: db}}
  policyTypes: ["Ingress","Egress"]
  ingress:
  - from: [{podSelector: {matchLabels: {role: frontend}}}]
    ports: [{protocol: TCP, port: 5432}]
  egress:
  - to: [{podSelector: {matchLabels: {role: monitoring}}}]
    ports: [{protocol: TCP, port: 8080}]
EOF
```

## Q11 - Security context pod
```bash
kubectl create namespace security
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: secure-app, namespace: security}
spec:
  securityContext: {runAsUser: 1000, runAsNonRoot: true}
  containers:
  - name: app
    image: nginx:alpine
    securityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      capabilities: {drop: ["ALL"]}
EOF
```

## Q12 - Build + run a Docker image
```bash
cat > /tmp/Dockerfile <<'DF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
DF
cat > /tmp/index.html <<'HTML'
<!DOCTYPE html><html><body><h1>Hello from CKAD Docker Question!</h1></body></html>
HTML
docker build -t my-nginx:v1 -f /tmp/Dockerfile /tmp
docker run -d --name my-web -p 8080:80 my-nginx:v1
```

## Q13 - Job (Never, backoffLimit 4, deadline 30)
```bash
kubectl create namespace jobs
kubectl create job data-processor -n jobs --image=busybox \
  -- sh -c 'for i in $(seq 1 5); do echo Processing item $i; sleep 2; done'
kubectl -n jobs patch job data-processor -p '{"spec":{"backoffLimit":4,"activeDeadlineSeconds":30}}'
# kubectl create job sets restartPolicy: Never already
```

## Q14 - Init container waits for a service
```bash
kubectl create namespace init-containers
kubectl create deployment myservice -n init-containers --image=nginx
kubectl expose deployment myservice -n init-containers --port=80
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: app-with-init, namespace: init-containers}
spec:
  volumes: [{name: shared, emptyDir: {}}]
  initContainers:
  - name: wait
    image: busybox
    command: ["sh","-c","until nslookup myservice; do echo waiting for myservice; sleep 2; done"]
    volumeMounts: [{name: shared, mountPath: /shared}]
  containers:
  - {name: app, image: nginx, volumeMounts: [{name: shared, mountPath: /shared}]}
EOF
```

## Q15 - Helm install + save notes
```bash
kubectl create namespace helm-basics
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install nginx-release bitnami/nginx -n helm-basics
helm get notes nginx-release -n helm-basics > /tmp/release-notes.txt
```

## Q16 - Startup + liveness + readiness probes
```bash
kubectl create namespace health-checks
kubectl run health-check-pod -n health-checks --image=nginx $do > h.yaml
```
Add to the container, then apply:
```yaml
    startupProbe:   {httpGet: {path: /, port: 80}, initialDelaySeconds: 10, periodSeconds: 3, failureThreshold: 3}
    livenessProbe:  {httpGet: {path: /, port: 80}, initialDelaySeconds: 15, periodSeconds: 5, failureThreshold: 3}
    readinessProbe: {httpGet: {path: /, port: 80}, initialDelaySeconds: 5,  periodSeconds: 3, failureThreshold: 3}
```

## Q17 - Lifecycle hooks + grace period
```bash
kubectl create namespace pod-lifecycle
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: lifecycle-pod, namespace: pod-lifecycle}
spec:
  terminationGracePeriodSeconds: 30
  containers:
  - name: nginx
    image: nginx
    lifecycle:
      postStart: {exec: {command: ["sh","-c","echo 'Welcome to the pod!' > /usr/share/nginx/html/welcome.txt"]}}
      preStop:   {exec: {command: ["sh","-c","sleep 10"]}}
EOF
```

## Q18 - CRD + custom resource
```bash
kubectl create namespace crd-demo
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata: {name: applications.training.ckad.io}
spec:
  group: training.ckad.io
  scope: Namespaced
  names: {plural: applications, singular: application, kind: Application, shortNames: [app]}
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: [image, replicas]
            properties:
              image:    {type: string}
              replicas: {type: integer}
EOF
cat <<EOF | kubectl apply -f -
apiVersion: training.ckad.io/v1
kind: Application
metadata: {name: my-app, namespace: crd-demo}
spec: {image: nginx:1.19.0, replicas: 3}
EOF
```

## Q19 - kubectl custom-columns / jsonpath to files
```bash
kubectl create namespace custom-columns-demo
kubectl get pods -A \
  -o custom-columns='NAME:.metadata.name,NAMESPACE:.metadata.namespace,IMAGES:.spec.containers[*].image' \
  > /tmp/pod-images.txt
kubectl get pods -A \
  -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.namespace}{"\t"}{range .spec.containers[*]}{.image}{","}{end}{"\n"}{end}' \
  > /tmp/all-container-images.txt
```

## Q20 - Pod pulling env from literals + ConfigMap + Secret + CM volume
```bash
kubectl create namespace pod-configuration
kubectl create configmap app-config -n pod-configuration \
  --from-literal=DB_HOST=mysql --from-literal=DB_PORT=3306
kubectl create secret generic app-secret -n pod-configuration \
  --from-literal=API_KEY=abc123 --from-literal=API_SECRET=s3cr3t
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: config-pod, namespace: pod-configuration}
spec:
  volumes: [{name: cfg, configMap: {name: app-config}}]
  containers:
  - name: nginx
    image: nginx
    env:
    - {name: APP_ENV, value: production}
    - {name: DEBUG, value: "false"}
    - {name: DB_HOST, valueFrom: {configMapKeyRef: {name: app-config, key: DB_HOST}}}
    - {name: DB_PORT, valueFrom: {configMapKeyRef: {name: app-config, key: DB_PORT}}}
    - {name: API_KEY, valueFrom: {secretKeyRef: {name: app-secret, key: API_KEY}}}
    - {name: API_SECRET, valueFrom: {secretKeyRef: {name: app-secret, key: API_SECRET}}}
    volumeMounts: [{name: cfg, mountPath: /etc/app-config}]
EOF
```
