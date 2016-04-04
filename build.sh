#!/bin/bash
set -e
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

# Artifact URL is delivered by OpenShift 3 Jenkins Plugin in Git Commit parameter
ARTIFACT_URL=`echo "${BUILD}" | jq -r .spec.revision.git.commit`

if [ -n "${ARTIFACT_URL}" ] && [ ${ARTIFACT_URL} != "null" ]; then
  DOCKER_CONTEXT_URL="${ARTIFACT_URL}"
fi

curl ${CURL_OPTS} ${DOCKER_CONTEXT_URL} -o docker-context.tar.gz
tar xvfz docker-context.tar.gz
rm -f docker-context.tar.gz

echo -e ".build_tag\n.d2i" >> .dockerignore

popd

if [ -x "${BUILD_DIR}/.d2i/pre_build" ]; then
  "${BUILD_DIR}/.d2i/pre_build" "$BUILD_DIR" "$TAG"
fi

docker build --rm -t "${TAG}" "${BUILD_DIR}"

if [[ -d /var/run/secrets/openshift.io/push ]] && [[ ! -e /root/.dockercfg ]]; then
  cp /var/run/secrets/openshift.io/push/.dockercfg /root/.dockercfg
fi

if [ -n "${OUTPUT_IMAGE}" ] || [ -s "/root/.dockercfg" ]; then
  docker push "${TAG}"

  if [ -e "${BUILD_DIR}/.build_tag" ]; then
    BUILD_TAG="${TAG%:*}:"`cat ${BUILD_DIR}/.build_tag`
    docker tag -f "${TAG}" "${BUILD_TAG}"
    docker push "${BUILD_TAG}"

    if [ -x "${BUILD_DIR}/.d2i/post_build" ]; then
      "${BUILD_DIR}/.d2i/post_build" "$BUILD_DIR" "$TAG"
    fi
  fi
fi
