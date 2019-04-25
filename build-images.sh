#!/bin/bash
set -eu

# optional version argument
version="${1:-}"
# get all versions
versions=($(ls -d [0-9]*))
# get the last element of sorted version folders
latest_version=${versions[${#versions[@]}-1]}

REVISION=$(git rev-parse --short HEAD)
CREATED=$(date -u +”%Y-%m-%dT%H:%M:%SZ”)

for v in "${versions[@]}"; do
  if [ -z "${version}" ] || [ "${version}" == "${v}" ]; then
    # read full version from Dockerfile
    full_version=$(grep "ARG JANUS_VERSION" ${v}/Dockerfile | cut -d"=" -f 2)
    # build and test image
    docker build -f "${v}/Dockerfile" -t "janusgraph/janusgraph:${full_version}" ${v} --build-arg REVISION=$REVISION --build-arg CREATED=$CREATED
    ./test-image.sh "janusgraph/janusgraph:${full_version}"
    # add relevant tags
    docker tag "janusgraph/janusgraph:${full_version}" "janusgraph/janusgraph:${v}"
    if [ "${v}" == "${latest_version}" ]; then
      docker tag "janusgraph/janusgraph:${v}" "janusgraph/janusgraph:latest"
    fi
  fi
done
