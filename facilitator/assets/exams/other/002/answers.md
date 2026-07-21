# Helm Speedrun — Solutions

All tasks are Helm CLI workflows.

---

## Q1 — Helm version
```bash
mkdir -p /tmp/exam/q1
helm version > /tmp/exam/q1/helm-version.txt
```

## Q2 — Add + update repo
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
```

## Q3 — Search chart
```bash
mkdir -p /tmp/exam/q3
helm search repo bitnami/nginx > /tmp/exam/q3/nginx-charts.txt
```

## Q4 — Install with value overrides
```bash
helm install web-server bitnami/nginx -n default \
  --set service.type=NodePort --set service.nodePorts.http=30080
```

## Q5 — List releases (all namespaces)
```bash
mkdir -p /tmp/exam/q5
helm list -A > /tmp/exam/q5/releases.txt
```

## Q6 — Status + rendered manifests
```bash
mkdir -p /tmp/exam/q6
helm status web-server -n default > /tmp/exam/q6/web-server-status.txt
helm get manifest web-server -n default > /tmp/exam/q6/web-server-manifests.txt
```

## Q7 — Upgrade replica count
```bash
helm upgrade web-server bitnami/nginx -n default --reuse-values --set replicaCount=3
kubectl get pods -n default -l app.kubernetes.io/instance=web-server
```

## Q8 — Values file install
```bash
mkdir -p /tmp/exam/q8
cat > /tmp/exam/q8/redis-values.yaml <<'YML'
auth:
  password: "password123"
master:
  persistence:
    enabled: true
  resources:
    limits:
      memory: 256Mi
      cpu: 100m
YML
helm install cache-db bitnami/redis -n default -f /tmp/exam/q8/redis-values.yaml
```

## Q9 — Create + edit a chart
```bash
cd /tmp/exam/q9 2>/dev/null || cd /tmp
helm create webapp
sed -i 's/^description:.*/description: A simple web application/' webapp/Chart.yaml
sed -i 's/^appVersion:.*/appVersion: "1.2.3"/' webapp/Chart.yaml
```

## Q10 — Package + local repo
```bash
helm package webapp
mkdir -p /tmp/exam/q10/charts
mv webapp-*.tgz /tmp/exam/q10/charts/
helm repo index /tmp/exam/q10/charts
helm repo add localrepo /tmp/exam/q10/charts
helm repo list
```

## Q11 — Rollback to first revision
```bash
helm history web-server -n default
helm rollback web-server 1 -n default
helm history web-server -n default          # confirm new revision points back to rev 1
kubectl get pods -n default -l app.kubernetes.io/instance=web-server
```

## Q12 — Debug a broken release
```bash
mkdir -p /tmp/exam/q12
helm status buggy-app -n default
helm get values buggy-app -n default
helm get manifest buggy-app -n default | kubectl apply --dry-run=server -f - 2>&1 | tee -a /tmp/exam/q12/diagnosis.txt
kubectl get pods -n default -l app.kubernetes.io/instance=buggy-app
kubectl describe pod -n default -l app.kubernetes.io/instance=buggy-app | grep -A5 Events >> /tmp/exam/q12/diagnosis.txt
# after identifying the bad value (e.g. wrong image/tag), fix it:
helm upgrade buggy-app <chart> -n default --reuse-values --set image.tag=<valid-tag>
```
