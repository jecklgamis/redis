#!/bin/bash
set -ex

REDIS_PASSWORD="${REDIS_PASSWORD:?REDIS_PASSWORD must be set}"

mkdir -p /data

exec /redis/src/redis-server \
  --protected-mode no \
  --requirepass "$REDIS_PASSWORD" \
  --port 0 \
  --tls-port 6379 \
  --tls-cert-file /redis/tls/redis.crt \
  --tls-key-file /redis/tls/redis.key \
  --tls-ca-cert-file /redis/tls/ca.crt \
  --tls-auth-clients no \
  --dir /data

