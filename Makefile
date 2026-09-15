BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
IMAGE := jecklgamis/redis:$(BRANCH)
REDIS_PASSWORD ?= changeme

default:
	cat ./Makefile
image:
	docker build -t $(IMAGE) .
run:
	docker run -p 6379:6379 -e REDIS_PASSWORD=$(REDIS_PASSWORD) $(IMAGE)
run-bash:
	docker run -i -t $(IMAGE) /bin/bash
up: image run
