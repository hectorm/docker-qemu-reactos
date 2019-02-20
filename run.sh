#!/bin/sh

set -eu
export LC_ALL=C

DOCKER_IMAGE_NAMESPACE=hectormolinero
DOCKER_IMAGE_NAME=qemu-reactos
DOCKER_IMAGE_VERSION=latest
DOCKER_IMAGE=${DOCKER_IMAGE_NAMESPACE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
DOCKER_CONTAINER=${DOCKER_IMAGE_NAME}

imageExists() { [ -n "$(docker images -q "$1")" ]; }
containerExists() { docker ps -aqf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }
containerIsRunning() { docker ps -qf name="$1" --format '{{.Names}}' | grep -Fxq "$1"; }

if ! imageExists "${DOCKER_IMAGE}"; then
	>&2 printf -- '%s\n' "${DOCKER_IMAGE} image doesn't exist!"
	exit 1
fi

if containerIsRunning "${DOCKER_CONTAINER}"; then
	printf -- '%s\n' "Stopping \"${DOCKER_CONTAINER}\" container..."
	docker stop "${DOCKER_CONTAINER}" >/dev/null
fi

if containerExists "${DOCKER_CONTAINER}"; then
	printf -- '%s\n' "Removing \"${DOCKER_CONTAINER}\" container..."
	docker rm "${DOCKER_CONTAINER}" >/dev/null
fi

printf -- '%s\n' "Creating \"${DOCKER_CONTAINER}\" container..."
docker run --detach \
	--name "${DOCKER_CONTAINER}" \
	--hostname "${DOCKER_CONTAINER}" \
	--restart on-failure:3 \
	--log-opt max-size=32m \
	--publish '127.0.0.1:5900:5900/tcp' \
	--publish '127.0.0.1:6080:6080/tcp' \
	--publish '127.0.0.1:15900:5900/tcp' \
	--privileged --env QEMU_KVM=true \
	"${DOCKER_IMAGE}" "$@" >/dev/null

printf -- '%s\n\n' 'Done!'
exec docker logs -f "${DOCKER_CONTAINER}"
