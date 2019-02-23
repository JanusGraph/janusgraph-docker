#!/usr/bin/env bash
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
		${COMMENT}
		${COMMENT} PLEASE DO NOT EDIT IT DIRECTLY.
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
  if [[ $version =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
    # given latest version, get versioned directory
    dir=$(echo $version | cut -d"." -f 1-2)
    latest_version=$version
  else
    # given versioned directory, query GitHub API for latest version
    dir="$version"
    url=https://api.github.com/repos/janusgraph/janusgraph/tags
    filter='[.[].name|select(test("v'${version}'.[0-9]+$"))|ltrimstr("v")][0]'
    latest_version=$(curl -s "$url" | jq ''$filter'' | tr -d '"')
    if [ ${latest_version} == "null" ]; then
      echo "Version not found"
      exit 1
    fi
  fi

  echo "$version/$latest_version"
  mkdir -p $dir/conf $dir/scripts

  # copy Dockerfile and update version
  template-generated-warning "#" > "$dir/Dockerfile"
  sed -e 's!^\(ENV JANUS_VERSION\)\s*=.*!\1='"${latest_version}"'!' \
    build/Dockerfile-openjdk8.template >> "$dir/Dockerfile"

  # copy docker-entrypoint
  head -n 1 build/docker-entrypoint.sh > $dir/docker-entrypoint.sh
  template-generated-warning "#" >> $dir/docker-entrypoint.sh
  awk 'NR>1' build/docker-entrypoint.sh >> $dir/docker-entrypoint.sh

  # copy resources
  copy-with-template-generated-warning conf/janusgraph-berkeleyje-lucene-server.properties "#"
  copy-with-template-generated-warning conf/log4j-server.properties "#"
  copy-with-template-generated-warning scripts/remote-connect.groovy "//"
done
