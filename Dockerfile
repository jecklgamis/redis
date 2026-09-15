FROM ubuntu:24.04 AS builder
LABEL org.opencontainers.image.authors="Jerrico Gamis <jecklgamis@gmail.com>"

RUN apt update -y && apt install -y curl build-essential libssl-dev pkg-config openssl && apt clean all

ENV REDIS_PKG_NAME=redis-8.8.2

RUN cd /usr/local && curl -O https://download.redis.io/releases/$REDIS_PKG_NAME.tar.gz
RUN cd /usr/local && tar xvf $REDIS_PKG_NAME.tar.gz && rm -f  $REDIS_PKG_NAME.tar.gz
RUN ln -s /usr/local/$REDIS_PKG_NAME /redis
RUN cd /redis && make BUILD_TLS=yes

RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /redis/redis.conf

# Self-signed CA + server cert for TLS. Fine for local/dev use — replace
# with certs from a real CA before running this anywhere untrusted.
RUN mkdir -p /redis/tls && cd /redis/tls && \
    openssl genrsa -out ca.key 4096 && \
    openssl req -x509 -new -nodes -sha256 -days 3650 -key ca.key -out ca.crt -subj "/CN=redis-dev-ca" && \
    openssl genrsa -out redis.key 2048 && \
    openssl req -new -sha256 -key redis.key -out redis.csr -subj "/CN=redis" && \
    openssl x509 -req -sha256 -days 3650 -in redis.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out redis.crt && \
    rm -f redis.csr ca.key ca.srl

FROM ubuntu:24.04
LABEL org.opencontainers.image.authors="Jerrico Gamis <jecklgamis@gmail.com>"

RUN apt update -y && apt install -y libssl3 && apt clean all
RUN groupadd -r redis && useradd -r -gredis redis

COPY --from=builder --chown=redis:redis /redis/src/redis-server /redis/src/
COPY --from=builder --chown=redis:redis /redis/src/redis-cli /redis/src/
COPY --from=builder --chown=redis:redis /redis/src/redis-benchmark /redis/src/
COPY --from=builder --chown=redis:redis /redis/src/redis-check-aof /redis/src/
COPY --from=builder --chown=redis:redis /redis/src/redis-check-rdb /redis/src/
COPY --from=builder --chown=redis:redis /redis/redis.conf /redis/
COPY --from=builder --chown=redis:redis /redis/tls /redis/tls

COPY run-redis.sh /usr/local/bin

CMD ["/usr/local/bin/run-redis.sh"]
