#!/bin/bash
set -eu

# optional version argument
version="${1:-}"
# get all versions
versions=($(ls -d [0-9]*))
# get the last element of sorted version folders
latest_version=${versions[${#versions[@]}-1]}

for v in "${versions[@]}"; do
  if [ -z "${version}" ] || [ "${version}" == "${v}" ]; then
    # read full version from Dockerfile
    full_version=$(grep "ARG JANUS_VERSION" ${v}/Dockerfile | cut -d"=" -f 2)
    # push relevant tags
    docker push "janusgraph/janusgraph:${full_version}"
    docker push "janusgraph/janusgraph:${v}"
    if [ "${v}" == "${latest_version}" ]; then
      docker push "janusgraph/janusgraph:latest"
    fi
  fi
done
