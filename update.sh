#!/usr/bin/env bash
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

set -Eeuo pipefail

cd $(dirname $0)

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
    versions=($(ls -d [0-9]*))
fi

# generate header for auto-generated files
template-generated-warning() {
COMMENT=$1
cat <<-EOD
${COMMENT}
${COMMENT} NOTE: THIS FILE IS GENERATED VIA "update.sh"
${COMMENT} DO NOT EDIT IT DIRECTLY; CHANGES WILL BE OVERWRITTEN.
${COMMENT}
EOD
}

# copy template file to version directory and add header
copy-with-template-generated-warning() {
  FILE=$1
  COMMENT=$2
  template-generated-warning "${COMMENT}" > $dir/$FILE
  cat build/$FILE >> $dir/$FILE
}

for version in "${versions[@]}"; do
  if [[ $version =~ ^[0]+.[0-5](.[0-9]+)*$ ]]; then
    continue
  fi

  if [[ $version =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
    # given latest version, get versioned directory
    major_minor_version=$(echo $version | cut -d"." -f 1-2)
    latest_version=$version
  else
    # given versioned directory, query GitHub API for latest version
    major_minor_version="$version"
    url=https://api.github.com/repos/janusgraph/janusgraph/tags
    filter='[.[].name|select(test("v'${version}'.[0-9]+$"))|ltrimstr("v")][0]'
    latest_version=$(curl -s "$url" | jq ''$filter'' | tr -d '"')
    if [ ${latest_version} == "null" ]; then
      echo "Version not found"
      exit 1
    fi
  fi

  dir=$major_minor_version
  echo "$version/$latest_version"
  mkdir -p $dir/conf $dir/scripts

  # copy Dockerfile and update version
  template-generated-warning "#" > "$dir/Dockerfile"
  sed -e 's!^\(ARG JANUS_VERSION\)\s*=.*!\1='"${latest_version}"'!' \
    -e 's!{MAJOR_MINOR_VERSION_PLACEHOLDER}!'"${major_minor_version}"'!' \
    build/Dockerfile-openjdk8.template >> "$dir/Dockerfile"

  # copy docker-entrypoint
  head -n 1 build/docker-entrypoint.sh > $dir/docker-entrypoint.sh
  template-generated-warning "#" >> $dir/docker-entrypoint.sh
  awk 'NR>1' build/docker-entrypoint.sh >> $dir/docker-entrypoint.sh

  # copy load-initdb
  head -n 1 build/load-initdb.sh > $dir/load-initdb.sh
  template-generated-warning "#" >> $dir/load-initdb.sh
  awk 'NR>1' build/load-initdb.sh >> $dir/load-initdb.sh

  # copy resources
  copy-with-template-generated-warning conf/janusgraph-server.yaml "#"
  copy-with-template-generated-warning conf/janusgraph-berkeleyje-es-server.properties "#"
  copy-with-template-generated-warning conf/janusgraph-berkeleyje-lucene-server.properties "#"
  copy-with-template-generated-warning conf/janusgraph-berkeleyje-server.properties "#"
  copy-with-template-generated-warning conf/janusgraph-cql-es-server.properties "#"
  copy-with-template-generated-warning conf/janusgraph-cql-server.properties "#"
  copy-with-template-generated-warning conf/janusgraph-inmemory-server.properties "#"
  copy-with-template-generated-warning conf/log4j-server.properties "#"
  copy-with-template-generated-warning scripts/remote-connect.groovy "//"
done
