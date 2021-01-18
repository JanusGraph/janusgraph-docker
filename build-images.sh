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
# get the last element of sorted version folders
latest_version="${versions[${#versions[@]}-1]}"

REVISION="$(git rev-parse --short HEAD)"
CREATED="$(date -u +”%Y-%m-%dT%H:%M:%SZ”)"
IMAGE_NAME="docker.io/janusgraph/janusgraph"

echo "REVISION: ${REVISION}"
echo "CREATED: ${CREATED}"
echo "IMAGE_NAME: ${IMAGE_NAME}"

for v in "${versions[@]}"; do
  if [ -z "${version}" ] || [ "${version}" == "${v}" ]; then
    # prepare docker tags
    full_version="$(grep "ARG JANUS_VERSION" ${v}/Dockerfile | head -n 1 | cut -d"=" -f 2)"
    full_version_with_revision="${full_version}-${REVISION}"

    # build and test image
    docker build -f "${v}/Dockerfile" -t "${IMAGE_NAME}:${full_version}" ${v} --build-arg REVISION="$REVISION" --build-arg CREATED="$CREATED"
    ./test-image.sh "${IMAGE_NAME}:${full_version}"

    # add relevant tags
    docker tag "${IMAGE_NAME}:${full_version}" "${IMAGE_NAME}:${v}"
    echo "Successfully tagged ${IMAGE_NAME}:${v}"
    docker tag "${IMAGE_NAME}:${full_version}" "${IMAGE_NAME}:${full_version_with_revision}"
    echo "Successfully tagged ${IMAGE_NAME}:${full_version_with_revision}"
    if [ "${v}" == "${latest_version}" ]; then
      docker tag "${IMAGE_NAME}:${v}" "${IMAGE_NAME}:latest"
      echo "Successfully tagged ${IMAGE_NAME}:latest"
    fi
  fi
done
