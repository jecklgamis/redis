BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
IMAGE := jecklgamis/redis:$(BRANCH)

default:
	cat ./Makefile
image:
	docker build -t $(IMAGE) .
run:
	docker run -p 6379:6379 $(IMAGE)
run-bash:
	docker run -i -t $(IMAGE) /bin/bash
up: image run
