# Mock Exam 02 Solutions

## Question 1: Service Discovery and DNS

```bash
mkdir -p /tmp/exam
echo "web-ui.frontend.svc.cluster.local" > /tmp/exam/q1_dns_name.txt
```

## Question 2: Deployment Rolling Update and Rollback

```bash
kubectl rollout history deployment/payment-service
kubectl rollout undo deployment/payment-service --to-revision=2
```

## Question 3: Secrets and Environment Variables

```bash
kubectl create secret generic db-creds \
  --from-literal=username=dbuser \
  --from-literal=password=secret123 \
  --from-literal=database=appdb

kubectl set env --from=secret/db-creds deployment/app-deploy
```

## Question 4: DaemonSet Configuration

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
spec:
  selector:
    matchLabels:
      app: monitoring-agent
  template:
    metadata:
      labels:
        app: monitoring-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      containers:
      - name: agent
        image: datadog/agent:latest
```

## Question 5: Cluster API Server Debugging

```bash
mkdir -p /tmp/exam
echo "kubectl logs -n kube-system -l component=kube-apiserver" > /tmp/exam/q5_command.txt
```

## Question 6

```bash
mkdir -p /tmp/exam
cat > /tmp/exam/q6_etcd_backup.txt <<'CMD'
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
CMD
```

## Question 7

```bash
kubectl taint node k3d-cluster-agent-0 dedicated=special:NoSchedule
kubectl run toleration-pod --image=nginx --overrides='{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"special","effect":"NoSchedule"}]}}'
```

## Question 8

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  volumes:
  - name: work
    emptyDir: {}
  initContainers:
  - name: init
    image: busybox
    command: ["sh","-c","echo hello > /work/index.html"]
    volumeMounts:
    - name: work
      mountPath: /work
  containers:
  - name: web
    image: nginx
    volumeMounts:
    - name: work
      mountPath: /usr/share/nginx/html
```

## Question 9

```bash
kubectl create serviceaccount build-sa
kubectl run sa-pod --image=nginx --overrides='{"spec":{"serviceAccountName":"build-sa"}}'
```

## Question 10

```bash
kubectl create priorityclass high-prio --value=1000000
kubectl run prio-pod --image=nginx --overrides='{"spec":{"priorityClassName":"high-prio"}}'
```

## Question 11

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
```

## Question 12

```bash
kubectl patch deployment frontend --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
kubectl rollout status deployment/frontend
```

## Question 13

```bash
kubectl -n apps create configmap app-cfg --from-literal=MODE=prod
kubectl -n apps rollout status deployment/cfg-app
```

## Question 14

```bash
kubectl patch svc web2-svc -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'
```

## Question 15

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-allow
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          env: prod
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

> If `namespaceSelector` and `podSelector` were in two separate `- ` list items, they would be ORed instead of ANDed - the classic exam trap.

## Question 16

```bash
kubectl expose deployment np-app --name=np-svc --port=80 --target-port=80 --type=NodePort --dry-run=client -o yaml > np.yaml
# edit np.yaml -> ports[0].nodePort: 30080
kubectl apply -f np.yaml
```

## Question 17

```bash
mkdir -p /tmp/exam
cat > /tmp/exam/q17_upgrade.txt <<'CMD'
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
apt-get update && apt-get install -y kubeadm=1.33.1-*
kubeadm upgrade node
apt-get install -y kubelet=1.33.1-*
systemctl daemon-reload
systemctl restart kubelet
kubectl uncordon <node>
CMD
```
