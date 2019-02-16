#!/bin/bash

versions=$(ls -d -- */ | sort | grep -v example)
# strip trailing slashes
versions=${versions%/}

for v in ${versions};
do
  docker push "janusgraph/janusgraph:${v}"
done

docker push "janusgraph/janusgraph:latest"
