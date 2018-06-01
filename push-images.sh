#!/bin/bash

versions=$(ls -d -- */ | sort | grep -v example)
# strip trailing slashes
versions=${versions%/}
# get the last element of sorted version folders
latest_version=${versions[${#versions[@]}-1]}

for v in ${versions};
do
  docker push "experoinc/janusgraph:${v}"
done

docker push "experoinc/janusgraph:latest"
