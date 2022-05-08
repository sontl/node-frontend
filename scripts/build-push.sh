#!/usr/bin/env bash

set -e
set -x
DOCKER_USERNAME=sontl
DOCKER_PASSWORD=
NodeMajor=16
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

DockerTag="${NodeMajor}"

docker buildx build --push --platform linux/amd64,linux/arm64/v8 -t "sontl/multiarch-node-frontend:${DockerTag}" --build-arg NodeMajor=$NodeMajor  .


