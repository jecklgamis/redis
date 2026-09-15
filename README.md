## redis

[![Build](https://github.com/jecklgamis/redis/actions/workflows/build.yaml/badge.svg)](https://github.com/jecklgamis/redis/actions/workflows/build.yaml)

A single-instance Redis Docker image, built from source with TLS and password authentication enabled.

## Features

* Redis 8.8.2 built from source (multi-stage build - no compiler/dev toolchain in the final image)
* TLS-only listener (self-signed CA + cert generated at build time; plaintext port disabled)
* Password authentication required via `REDIS_PASSWORD` (`--requirepass`)
* Data persisted under `/data`
* Docker image on Docker Hub, plus a Helm chart for deploying to Kubernetes

## Quick Start

```bash
docker run -d --name redis -p 6379:6379 -e REDIS_PASSWORD=some-strong-password jecklgamis/redis:main
```

Connect with `redis-cli`:

```bash
docker exec -it redis /redis/src/redis-cli --tls --cacert /redis/tls/ca.crt -p 6379 -a some-strong-password ping
```

The self-signed cert is only meant for local/dev use - anything beyond that should mount real certs and/or terminate
TLS at a proxy in front of it.

## Getting Started

```bash
git clone https://github.com/jecklgamis/redis.git
cd redis
make up REDIS_PASSWORD=some-strong-password
```

See the [`Makefile`](Makefile) for other targets (`image`, `run`, `run-bash`).

## Deploying to Kubernetes

A Helm chart is available under [`deployment/k8s/helm/chart`](deployment/k8s/helm/chart) for a single-instance
deployment with persistence, a Secret for `REDIS_PASSWORD`, and a ClusterIP service.

Generate a random password and store it as a Secret directly (keeps it out of `values.yaml`, shell history via
`--set`, and Helm's own release values):

```bash
kubectl create namespace redis
REDIS_PASSWORD=$(openssl rand -base64 24)
kubectl create secret generic redis-credentials -n redis --from-literal=REDIS_PASSWORD="$REDIS_PASSWORD"
```

Install the chart, pointing it at that Secret:

```bash
cd deployment/k8s/helm/chart
helm install redis . -n redis --set existingSecretName=redis-credentials --wait
```

See [`deployment/k8s/helm/chart/values.yaml`](deployment/k8s/helm/chart/values.yaml) for other configurable options.

### Retrieving the password later

```bash
kubectl get secret redis-credentials -n redis -o jsonpath='{.data.REDIS_PASSWORD}' | base64 -d
```

### Getting the TLS CA cert

The self-signed CA cert is baked into the image at `/redis/tls/ca.crt` (same cert across pod restarts - it's part
of the image, not regenerated per-pod; a new one is only generated when the image itself is rebuilt). Pull it out
of a running pod:

```bash
POD_NAME=$(kubectl get pods -n redis -l "app.kubernetes.io/name=redis,app.kubernetes.io/instance=redis" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n redis $POD_NAME -- cat /redis/tls/ca.crt > ca.crt
```

Then connect from any client:

```bash
redis-cli --tls --cacert ca.crt -h <host> -p 6379 -a "$REDIS_PASSWORD" ping
```

### Accessing it locally

The Service is `ClusterIP` (internal-only), so from your machine you need to port-forward. In one terminal:

```bash
kubectl port-forward -n redis svc/redis 6379:6379
```

In another, connect using the CA cert and password from above:

```bash
redis-cli --tls --cacert ca.crt -h 127.0.0.1 -p 6379 -a "$REDIS_PASSWORD" ping
```
