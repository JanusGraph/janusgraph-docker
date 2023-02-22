#!/bin/bash
#
# Copyright 2019 JanusGraph Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu

# optional version argument
version="${1:-}"
# get all versions
versions=($(ls -d [0-9]*))

get_full_version () {
  echo "$(grep "ARG JANUS_VERSION" $1/Dockerfile | head -n 1 | cut -d"=" -f 2)"
}

get_latest_version () {
  for v in "${versions[@]}"; do
    full_version=$(get_full_version $v)
    if [[ $full_version != *"-"* ]]; then
      latest_version="${v}"
    fi
  done
  echo $latest_version
}

# get the last element of sorted version folders
latest_version=$(get_latest_version)
echo "latest_version: ${latest_version}"

REVISION="$(git rev-parse --short HEAD)"
CREATED="$(date -u +”%Y-%m-%dT%H:%M:%SZ”)"
IMAGE_NAME="docker.io/janusgraph/janusgraph"
PLATFORMS="linux/amd64,linux/arm64"

echo "REVISION: ${REVISION}"
echo "CREATED: ${CREATED}"
echo "IMAGE_NAME: ${IMAGE_NAME}"

# enable buildkit
export DOCKER_BUILDKIT=1

for v in "${versions[@]}"; do
  if [ -z "${version}" ] || [ "${version}" == "${v}" ]; then
    # prepare docker tags
    full_version=$(get_full_version $v)
    full_version_with_revision="${full_version}-${REVISION}"

    # build and push the multi-arch image
    # unfortunately, when building a multi-arch image, we have to push it right after building it,
    # rather than save locally and then push it. see https://github.com/docker/buildx/issues/166
    if [[ $full_version != *"-"* ]]; then
      if [ "${v}" == "${latest_version}" ]; then
        docker buildx build ${v}\
          --platform "${PLATFORMS}" -f "${v}/Dockerfile" \
          -t "${IMAGE_NAME}:${full_version}" \
          -t "${IMAGE_NAME}:${v}" \
          -t "${IMAGE_NAME}:${full_version_with_revision}" \
          -t "${IMAGE_NAME}:latest" \
          --build-arg REVISION="$REVISION" \
          --build-arg CREATED="$CREATED" \
          --push
      else
        docker buildx build ${v}\
          --platform "${PLATFORMS}" -f "${v}/Dockerfile" \
          -t "${IMAGE_NAME}:${full_version}" \
          -t "${IMAGE_NAME}:${v}" \
          -t "${IMAGE_NAME}:${full_version_with_revision}" \
          --build-arg REVISION="$REVISION" \
          --build-arg CREATED="$CREATED" \
          --push
      fi
    else
      docker buildx build ${v}\
        --platform "${PLATFORMS}" -f "${v}/Dockerfile" \
        -t "${IMAGE_NAME}:${full_version}" \
        -t "${IMAGE_NAME}:${full_version_with_revision}" \
        --build-arg REVISION="$REVISION" \
        --build-arg CREATED="$CREATED" \
        --push
    fi
  fi
done
