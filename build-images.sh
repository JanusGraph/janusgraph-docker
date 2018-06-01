#!/bin/bash

versions=$(ls -d -- */ | sort | grep -v example)
# strip trailing slashes
versions=${versions%/}
# get the last element of sorted version folders
latest_version=${versions[${#versions[@]}-1]}

for v in ${versions};
do
  docker build -f "${v}/Dockerfile" -t "experoinc/janusgraph:${v}" ${v}
done

docker tag "experoinc/janusgraph:${latest_version}" "experoinc/janusgraph:latest"
