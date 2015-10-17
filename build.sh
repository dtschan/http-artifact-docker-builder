#!/bin/bash
set -o pipefail
#IFS=$'\n\t'

DOCKER_SOCKET=/var/run/docker.sock

if [ ! -e "${DOCKER_SOCKET}" ]; then
  echo "Docker socket missing at ${DOCKER_SOCKET}"
  exit 1
fi

if [ -n "${OUTPUT_IMAGE}" ]; then
  TAG="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"
fi

BUILD_DIR=$(mktemp --directory --suffix=docker-build)
pushd "${BUILD_DIR}"

if [ -e /etc/secret-volume/.netrc ]; then
  CURL_OPTS="--netrc-file /etc/secret-volume/.netrc"
else
  CURL_OPTS=""
fi

curl ${CURL_OPTS} ${DOCKERFILE_URL} -O

popd
docker build --rm -t "${TAG}" "${BUILD_DIR}"

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
  docker push "${TAG}"
fi
