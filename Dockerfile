FROM ubuntu:24.04 AS builder
LABEL org.opencontainers.image.authors="Jerrico Gamis <jecklgamis@gmail.com>"

RUN apt update -y && apt install -y curl build-essential && apt clean all

ENV REDIS_PKG_NAME=redis-8.8.2

RUN cd /usr/local && curl -O https://download.redis.io/releases/$REDIS_PKG_NAME.tar.gz
RUN cd /usr/local && tar xvf $REDIS_PKG_NAME.tar.gz && rm -f  $REDIS_PKG_NAME.tar.gz
RUN ln -s /usr/local/$REDIS_PKG_NAME /usr/local/redis
RUN cd /usr/local/redis && make

RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /usr/local/redis/redis.conf

FROM ubuntu:24.04
LABEL org.opencontainers.image.authors="Jerrico Gamis <jecklgamis@gmail.com>"

RUN groupadd -r redis && useradd -r -gredis redis

COPY --from=builder --chown=redis:redis /usr/local/redis/src/redis-server /usr/local/redis/src/
COPY --from=builder --chown=redis:redis /usr/local/redis/src/redis-cli /usr/local/redis/src/
COPY --from=builder --chown=redis:redis /usr/local/redis/src/redis-benchmark /usr/local/redis/src/
COPY --from=builder --chown=redis:redis /usr/local/redis/src/redis-check-aof /usr/local/redis/src/
COPY --from=builder --chown=redis:redis /usr/local/redis/src/redis-check-rdb /usr/local/redis/src/
COPY --from=builder --chown=redis:redis /usr/local/redis/redis.conf /usr/local/redis/

COPY run-redis.sh /usr/local/bin

CMD ["/usr/local/bin/run-redis.sh"]
