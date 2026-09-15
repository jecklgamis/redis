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

```bash
cd deployment/k8s/helm
make install
```

See [`deployment/k8s/helm/chart/values.yaml`](deployment/k8s/helm/chart/values.yaml) for configurable options.
