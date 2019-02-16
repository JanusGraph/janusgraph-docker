#!/bin/bash

versions=$(ls -d -- */ | sort | grep -v example)
# strip trailing slashes
versions=${versions%/}
# get the last element of sorted version folders
latest_version=${versions[${#versions[@]}-1]}

for v in ${versions};
do
  docker build -f "${v}/Dockerfile" -t "janusgraph/janusgraph:${v}" ${v}
done

docker tag "janusgraph/janusgraph:${latest_version}" "janusgraph/janusgraph:latest"
