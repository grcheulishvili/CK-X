# Docker Speedrun — Solutions

All tasks are Docker CLI workflows. Commands assume the referenced files already exist under
`/tmp/exam/qN` where the task provides them.

---

## Q1 — Build and tag
```bash
docker build -t docker-speedrun:v1 /tmp/exam/q1
docker tag docker-speedrun:v1 docker-speedrun:latest
docker images | grep docker-speedrun
```

## Q2 — Run detached with port + env
```bash
docker run -d --name web-server -p 8080:80 -e NGINX_HOST=localhost nginx:alpine
```

## Q3 — Named volume
```bash
docker volume create data-volume
docker run --name volume-test -v data-volume:/app/data alpine:latest \
  sh -c "echo 'Docker volumes test' > /app/data/test.txt"
```

## Q4 — Multi-stage build
```bash
cat > /tmp/exam/q4/Dockerfile <<'DF'
FROM golang:1.17-alpine AS build
WORKDIR /src
COPY main.go .
RUN go build -o /app main.go

FROM alpine:latest
COPY --from=build /app /app
ENTRYPOINT ["/app"]
DF
docker build -t multi-stage:latest /tmp/exam/q4
```

## Q5 - systemd cgroup driver

```bash
cat > /etc/docker/daemon.json <<'JSON'
{ "exec-opts": ["native.cgroupdriver=systemd"] }
JSON
cat /etc/docker/daemon.json
```

Do **not** restart the daemon on this lab machine: there is no init system here and the
remaining Docker questions need the running daemon. On a real host the change takes effect
with `systemctl restart docker`, verified by `docker info | grep "Cgroup Driver"`.

## Q6 — json-file logging with rotation
```bash
docker run -d --name logging-test \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  nginx:alpine
```

## Q7 — Custom bridge network + DNS
```bash
docker network create --subnet 172.18.0.0/16 app-network
docker run -d --name app1 --network app-network alpine sleep 3600
docker run --name app2 --network app-network alpine ping -c 3 app1
```

## Q8 — HEALTHCHECK image
```bash
cat > /tmp/exam/q8/Dockerfile <<'DF'
FROM nginx:alpine
RUN apk add --no-cache curl
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1
DF
docker build -t healthy-app:latest /tmp/exam/q8
docker run -d --name healthy-app healthy-app:latest
docker inspect --format '{{.State.Health.Status}}' healthy-app
```

## Q9 — Manifest + platforms
```bash
mkdir -p /tmp/exam/q9
docker manifest inspect nginx:1.21.0 > /tmp/exam/q9/manifest.json
jq -r '.manifests[].platform | .os+"/"+.architecture' /tmp/exam/q9/manifest.json \
  > /tmp/exam/q9/platforms.txt
# (if manifest inspect is disabled: docker buildx imagetools inspect nginx:1.21.0)
```

## Q10 — Resource-limited container
```bash
docker run -d --name limited-resources --cpus=0.5 --memory=256m \
  stress stress --cpu 1
```

## Q11 — docker-compose stack
```bash
cat > /tmp/exam/q11/docker-compose.yml <<'YML'
services:
  web:
    image: nginx:alpine
    ports: ["8080:80"]
    networks: [appnet]
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: appdb
    volumes: [dbdata:/var/lib/postgresql/data]
    networks: [appnet]
volumes:
  dbdata:
networks:
  appnet:
YML
docker compose -f /tmp/exam/q11/docker-compose.yml up -d
```

## Q12 — Image inspection report
```bash
mkdir -p /tmp/exam/q12
{
  echo "Base image:  $(docker inspect -f '{{index .Config.Labels "base"}}' webapp:latest 2>/dev/null; docker history --no-trunc webapp:latest | tail -1)"
  echo "Layers:      $(docker image inspect -f '{{len .RootFS.Layers}}' webapp:latest)"
  echo "Exposed:     $(docker image inspect -f '{{json .Config.ExposedPorts}}' webapp:latest)"
  echo "Env:         $(docker image inspect -f '{{json .Config.Env}}' webapp:latest)"
  echo "Entrypoint:  $(docker image inspect -f '{{json .Config.Entrypoint}}' webapp:latest)"
} > /tmp/exam/q12/image-report.txt
```

## Q13 — Troubleshoot broken-container
```bash
mkdir -p /tmp/exam/q13
docker logs broken-container 2>&1 | tail -20
docker exec broken-container ls -l /app || true
# fix: create the missing config file
docker exec broken-container sh -c 'echo "{}" > /app/config.json'
{
  echo "Symptom: container error referencing /app/config.json"
  echo "Cause: /app/config.json was missing"
  echo "Fix: created /app/config.json inside the container"
} > /tmp/exam/q13/diagnosis.txt
```

## Q14 — Non-root user image
```bash
cat > /tmp/exam/q14/Dockerfile <<'DF'
FROM python:3.9-slim
RUN useradd -u 1001 appuser
WORKDIR /app
COPY app.py /app/app.py
USER appuser
ENTRYPOINT ["python","/app/app.py"]
DF
docker build -t secure-app:latest /tmp/exam/q14
docker run -d --name secure-app secure-app:latest
```

## Q15 — Optimize (caching, .dockerignore, fewer layers)
```bash
cat > /tmp/exam/q15/.dockerignore <<'IGN'
.git
node_modules
*.md
IGN
# Order: copy dependency manifests and install BEFORE copying source, so the
# dependency layer stays cached across code changes; chain RUNs to cut layers.
cat > /tmp/exam/q15/Dockerfile <<'DF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
ENTRYPOINT ["python","app.py"]
DF
docker build -t optimized-app:latest /tmp/exam/q15
```

## Q16 — Docker Content Trust
```bash
mkdir -p /tmp/exam/q16
cat > /tmp/exam/q16/dct-commands.sh <<'SH'
#!/bin/bash
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE="rootpass"
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE="repopass"
docker pull docker.io/library/alpine:latest        # verified pull (DCT on)
docker tag alpine:latest localhost:5000/alpine:signed
docker push localhost:5000/alpine:signed           # signs on push
docker trust inspect --pretty localhost:5000/alpine:signed
SH
chmod +x /tmp/exam/q16/dct-commands.sh
```
