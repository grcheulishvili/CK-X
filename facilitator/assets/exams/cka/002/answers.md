# CKA Assessment 02 — Solutions (imperative-first)

Reach for a `kubectl` generator first; drop to YAML only for resources with no generator
(PV/PVC/SC, StatefulSet, NetworkPolicy, Gateway, LimitRange/Quota, multi-rule Role, probes,
affinity, securityContext). For those, *generate a skeleton and edit* rather than typing YAML
cold: `export do='--dry-run=client -o yaml'`.

---

## Q1 — Dynamic PVC + pod mount

```bash
kubectl create namespace storage-task
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: data-pvc, namespace: storage-task}
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: standard
  resources: {requests: {storage: 2Gi}}
EOF
kubectl run data-pod -n storage-task --image=nginx $do > data-pod.yaml
```
Add to `data-pod.yaml` then `kubectl apply -f data-pod.yaml`:
```yaml
spec:
  volumes:
  - name: data
    persistentVolumeClaim: {claimName: data-pvc}
  containers:
  - name: data-pod
    image: nginx
    volumeMounts:
    - {name: data, mountPath: /usr/share/nginx/html}
```

## Q2 — Default StorageClass

```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-local
  annotations: {storageclass.kubernetes.io/is-default-class: "true"}
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
# find the old default and unset it
kubectl get sc            # note the one marked (default), e.g. local-path
kubectl annotate sc local-path storageclass.kubernetes.io/is-default-class-
kubectl get sc            # only fast-local should show (default)
```

## Q3 — Static PV with node affinity + PVC + pod

```bash
kubectl create namespace manual-storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata: {name: manual-pv}
spec:
  capacity: {storage: 1Gi}
  accessModes: ["ReadWriteOnce"]
  hostPath: {path: /mnt/data}
  storageClassName: manual
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - {key: kubernetes.io/hostname, operator: In, values: ["k3d-cluster-agent-0"]}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: manual-pvc, namespace: manual-storage}
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: manual
  resources: {requests: {storage: 1Gi}}
EOF
kubectl run manual-pod -n manual-storage --image=busybox \
  --overrides='{"spec":{"volumes":[{"name":"d","persistentVolumeClaim":{"claimName":"manual-pvc"}}],"containers":[{"name":"manual-pod","image":"busybox","command":["sleep","3600"],"volumeMounts":[{"name":"d","mountPath":"/data"}]}]}}'
```

## Q4 — Deployment + resources + HPA (autoscaling/v1)

```bash
kubectl create deployment scaling-app -n scaling --image=nginx --replicas=2
kubectl set resources deployment scaling-app -n scaling \
  --requests=cpu=200m,memory=256Mi --limits=cpu=500m,memory=512Mi
kubectl autoscale deployment scaling-app -n scaling --min=2 --max=5 --cpu-percent=70
# kubectl autoscale emits an autoscaling/v1 HPA by default
```

## Q5 — Deployment pinned by node affinity

```bash
kubectl label node k3d-cluster-agent-1 disk=ssd
kubectl create deployment app-scheduling -n scheduling --image=nginx --replicas=3 $do > app.yaml
```
Add under `spec.template.spec` then apply:
```yaml
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - {key: kubernetes.io/hostname, operator: In, values: ["k3d-cluster-agent-1"]}
```

## Q6 — Pod Security Admission (restricted) + secure pod

```bash
kubectl create namespace security
kubectl label namespace security \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: secure-pod, namespace: security}
spec:
  securityContext:
    runAsUser: 1000
    runAsNonRoot: true
    seccompProfile: {type: RuntimeDefault}
  volumes:
  - {name: html, emptyDir: {}}
  containers:
  - name: nginx
    image: nginx
    securityContext:
      runAsUser: 1000
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities: {drop: ["ALL"]}
    volumeMounts:
    - {name: html, mountPath: /usr/share/nginx/html}
EOF
```

## Q7 — Taint + toleration deploy + normal deploy

```bash
kubectl taint node k3d-cluster-agent-1 special-workload=true:NoSchedule
kubectl create deployment toleration-deploy -n scheduling --image=nginx --replicas=2 $do > tol.yaml
# add the toleration under spec.template.spec, then apply
kubectl create deployment normal-deploy -n scheduling --image=nginx --replicas=2
```
Toleration block for `tol.yaml`:
```yaml
      tolerations:
      - {key: special-workload, operator: Equal, value: "true", effect: NoSchedule}
```
> A toleration only *permits* scheduling on the tainted node; `normal-deploy` has none, so the taint repels it there.

## Q8 — StatefulSet + headless Service + volumeClaimTemplate

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: {name: web-svc, namespace: stateful}
spec:
  clusterIP: None
  selector: {app: web}
  ports: [{port: 80}]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: web, namespace: stateful}
spec:
  serviceName: web-svc
  replicas: 3
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts: [{name: www, mountPath: /usr/share/nginx/html}]
  volumeClaimTemplates:
  - metadata: {name: www}
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: cold
      resources: {requests: {storage: 1Gi}}
EOF
kubectl get pods -n stateful -w   # web-0, web-1, web-2 come up in order
```

## Q9 — Service discovery test (busybox)

```bash
kubectl create deployment web-app -n dns-debug --image=nginx --replicas=3
kubectl expose deployment web-app -n dns-debug --name=web-svc --port=80
kubectl run dns-test -n dns-debug --image=busybox \
  -- sh -c 'wget -qO- http://web-svc && wget -qO- http://web-svc.dns-debug.svc.cluster.local && sleep 36000'
kubectl create configmap dns-config -n dns-debug --from-literal=searches=dns-debug.svc.cluster.local
kubectl logs dns-test -n dns-debug     # confirm both fetches returned HTML
```

## Q10 — DNS resolution to a file

```bash
kubectl create deployment dns-app -n dns-config --image=nginx --replicas=2
kubectl expose deployment dns-app -n dns-config --name=dns-svc --port=80
kubectl run dns-tester -n dns-config --image=infoblox/dnstools \
  -- sh -c 'nslookup dns-svc > /tmp/dns-test.txt; nslookup dns-svc.dns-config.svc.cluster.local >> /tmp/dns-test.txt; sleep 36000'
kubectl exec dns-tester -n dns-config -- cat /tmp/dns-test.txt
```

## Q11 — Helm install

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
kubectl create namespace helm-test
helm install web-release bitnami/nginx -n helm-test \
  --set service.type=NodePort --set replicaCount=2
helm list -n helm-test
kubectl get pods -n helm-test
```

## Q12 — Kustomize base + overlay

```bash
mkdir -p /tmp/exam/kustomize/base /tmp/exam/kustomize/overlay
kubectl create deployment nginx --image=nginx --replicas=2 $do > /tmp/exam/kustomize/base/deployment.yaml
cat > /tmp/exam/kustomize/base/kustomization.yaml <<EOF
resources: [deployment.yaml]
EOF
cat > /tmp/exam/kustomize/overlay/kustomization.yaml <<EOF
resources: [../base]
namespace: kustomize
commonLabels: {environment: production}
replicas: [{name: nginx, count: 3}]
configMapGenerator:
- name: nginx-config
  literals: [index.html=Welcome to Production]
patches:
- target: {kind: Deployment, name: nginx}
  patch: |-
    - op: add
      path: /spec/template/spec/volumes
      value: [{name: nginx-index, configMap: {name: nginx-config}}]
    - op: add
      path: /spec/template/spec/containers/0/volumeMounts
      value: [{name: nginx-index, mountPath: /usr/share/nginx/html}]
EOF
kubectl create namespace kustomize
kubectl apply -k /tmp/exam/kustomize/overlay
```

## Q13 — Gateway API

```bash
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: main-gateway, namespace: gateway}
spec:
  gatewayClassName: traefik           # use the class present: kubectl get gatewayclass
  listeners:
  - {name: http, port: 80, protocol: HTTP}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: app-route, namespace: gateway}
spec:
  parentRefs: [{name: main-gateway}]
  rules:
  - matches: [{path: {type: PathPrefix, value: /app1}}]
    backendRefs: [{name: app1-svc, port: 8080}]
  - matches: [{path: {type: PathPrefix, value: /app2}}]
    backendRefs: [{name: app2-svc, port: 8080}]
EOF
for a in app1 app2; do
  kubectl create deployment $a -n gateway --image=nginx
  kubectl expose deployment $a -n gateway --name=${a}-svc --port=8080 --target-port=80
done
```

## Q14 — LimitRange + ResourceQuota

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata: {name: limits, namespace: limits}
spec:
  limits:
  - type: Container
    default: {cpu: 200m, memory: 256Mi}
    defaultRequest: {cpu: 100m, memory: 128Mi}
    max: {cpu: 500m, memory: 512Mi}
---
apiVersion: v1
kind: ResourceQuota
metadata: {name: quota, namespace: limits}
spec:
  hard: {requests.cpu: "2", requests.memory: 2Gi, limits.cpu: "2", limits.memory: 2Gi, pods: "5"}
EOF
kubectl create deployment test-limits -n limits --image=nginx --replicas=2
```

## Q15 — resource-consumer + HPA

```bash
kubectl create deployment resource-consumer -n monitoring \
  --image=gcr.io/kubernetes-e2e-test-images/resource-consumer:1.5 --replicas=3
kubectl set resources deployment resource-consumer -n monitoring \
  --requests=cpu=100m,memory=128Mi --limits=cpu=200m,memory=256Mi
kubectl autoscale deployment resource-consumer -n monitoring --min=3 --max=6 --cpu-percent=50
```

## Q16 — SA + multi-rule Role + binding + pod

```bash
kubectl create serviceaccount app-admin -n cluster-admin
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: app-admin-role, namespace: cluster-admin}
rules:
- {apiGroups: [""], resources: ["pods"], verbs: ["get","list","watch"]}
- {apiGroups: ["apps"], resources: ["deployments"], verbs: ["get","list","watch","update"]}
- {apiGroups: [""], resources: ["configmaps"], verbs: ["create","delete"]}
EOF
kubectl create rolebinding app-admin-rb -n cluster-admin \
  --role=app-admin-role --serviceaccount=cluster-admin:app-admin
kubectl run admin-pod -n cluster-admin --image=bitnami/kubectl:latest \
  --overrides='{"spec":{"serviceAccountName":"app-admin"}}' -- sleep 3600
# verify
kubectl auth can-i list pods --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin   # yes
kubectl auth can-i create pods --as=system:serviceaccount:cluster-admin:app-admin -n cluster-admin  # no
```

## Q17 — Tiered NetworkPolicies (web→api→db)

```bash
for d in web api; do kubectl create deployment $d -n network --image=nginx; kubectl label deploy $d -n network app=$d --overwrite; done
kubectl create deployment db -n network --image=postgres
kubectl set env deployment/db -n network POSTGRES_HOST_AUTH_METHOD=trust
kubectl label deploy db -n network app=db --overwrite
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny, namespace: network}
spec: {podSelector: {}, policyTypes: ["Ingress"]}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: api-from-web, namespace: network}
spec:
  podSelector: {matchLabels: {app: api}}
  policyTypes: ["Ingress"]
  ingress: [{from: [{podSelector: {matchLabels: {app: web}}}]}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: db-from-api, namespace: network}
spec:
  podSelector: {matchLabels: {app: db}}
  policyTypes: ["Ingress"]
  ingress: [{from: [{podSelector: {matchLabels: {app: api}}}]}]
EOF
```

## Q18 — Rolling update, record, history, rollback

```bash
kubectl create deployment app-v1 -n upgrade --image=nginx:1.19 --replicas=4
kubectl patch deployment app-v1 -n upgrade -p \
  '{"spec":{"strategy":{"rollingUpdate":{"maxUnavailable":1,"maxSurge":1}}}}'
kubectl set image deployment/app-v1 -n upgrade nginx=nginx:1.20
kubectl annotate deployment app-v1 -n upgrade kubernetes.io/change-cause="update to nginx:1.20"
kubectl rollout status deployment/app-v1 -n upgrade
mkdir -p /tmp/exam
kubectl rollout history deployment app-v1 -n upgrade > /tmp/exam/rollout-history.txt
kubectl rollout undo deployment app-v1 -n upgrade
```

## Q19 — PriorityClasses + anti-affinity

```bash
cat <<EOF | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: high-priority}
value: 1000
globalDefault: false
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: low-priority}
value: 100
globalDefault: false
EOF
# create both pods with priorityClassName + podAntiAffinity (topologyKey hostname)
kubectl run high-priority -n scheduling --image=nginx \
  --overrides='{"spec":{"priorityClassName":"high-priority","affinity":{"podAntiAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":[{"labelSelector":{"matchExpressions":[{"key":"tier","operator":"Exists"}]},"topologyKey":"kubernetes.io/hostname"}]}}}}' --labels=tier=high
kubectl run low-priority -n scheduling --image=nginx \
  --overrides='{"spec":{"priorityClassName":"low-priority"}}' --labels=tier=low
```
> Under node pressure the scheduler evicts `low-priority` first; simulate load with `polinux/stress` pods (`stress -c 4 -m 2 --vm-bytes 1G`).

## Q20 — Troubleshoot `failing-app`

```bash
kubectl -n troubleshoot patch deployment failing-app --type=json -p='[
  {"op":"replace","path":"/spec/template/spec/containers/0/ports/0/containerPort","value":80},
  {"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"256Mi"},
  {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/port","value":80}
]'
kubectl -n troubleshoot rollout status deployment/failing-app
kubectl -n troubleshoot get pods    # all 3 Running
```
> If the paths differ, `kubectl -n troubleshoot edit deployment failing-app` and fix the three
> fields directly (containerPort 8080→80, memory 64Mi→256Mi, livenessProbe port 8080→80).
