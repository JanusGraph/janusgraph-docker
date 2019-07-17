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

JANUS_PROPS="${JANUS_CONFIG_DIR}/janusgraph.properties"
GREMLIN_YAML="${JANUS_CONFIG_DIR}/gremlin-server.yaml"

# running as root; step down to run as janusgraph user
if [[ "$(id -u)" == "0" ]] && [[ "$1" == 'janusgraph' || "$1" == 'gremlin-console' || "$1" == 'gremlin-console-remote' ]]; then
  echo "Running root setup steps for '$1'"
  mkdir -p ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
  chown -R janusgraph:janusgraph ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
  usermod -d ${JANUS_HOME} janusgraph
  chmod 700 ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}

  exec chroot --skip-chdir --userspec janusgraph:janusgraph / "${BASH_SOURCE}" "$@"
fi

# running as non root user
if [[ "$1" == 'janusgraph' || "$1" == 'gremlin-console' || "$1" == 'gremlin-console-remote' ]] ; then
  echo "Running non-root setup steps for '$1'"
  # setup config directory
  mkdir -p ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
  cp conf/gremlin-server/janusgraph-${JANUS_PROPS_TEMPLATE}-server.properties ${JANUS_CONFIG_DIR}/janusgraph.properties
  cp conf/gremlin-server/gremlin-server.yaml ${JANUS_CONFIG_DIR}
  chown -R "$(id -u):$(id -g)" ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
  chmod 700 ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
  chmod -R 600 ${JANUS_CONFIG_DIR}/*

  # override hosts for remote connections with Gremlin Console
  if ! [ -z "${GREMLIN_REMOTE_HOSTS:-}" ]; then
    sed -i "s/hosts\s*:.*/hosts: [$GREMLIN_REMOTE_HOSTS]/" ${JANUS_HOME}/conf/remote.yaml
  fi

  # apply configuration from environment
  while IFS='=' read -r envvar_key envvar_val; do
    if [[ "${envvar_key}" =~ janusgraph\. ]] && [[ ! -z ${envvar_val} ]]; then
      # strip namespace and use properties file delimiter for janusgraph properties
      config_file=${JANUS_PROPS} delimiter="=" envvar_key=${envvar_key#"janusgraph."}
    elif [[ "${envvar_key}" =~ gremlinserver\. ]] && [[ ! -z ${envvar_val} ]]; then
      # strip namespace, use yaml delimiter and add space after delimiter for gremlinserver properties
      config_file=${GREMLIN_YAML} delimiter=":" envvar_key=${envvar_key#"gremlinserver."} envvar_val=" $envvar_val"
    else
      continue
    fi

    # if the line exists replace it; otherwise append it
    if grep -q -E "^\s*${envvar_key}\s*${delimiter}\.*" ${config_file}; then
      sed -ri "s#^(\s*${envvar_key}\s*${delimiter}).*#\\1${envvar_val}#" ${config_file}
    else
      echo "${envvar_key}${delimiter}${envvar_val}" >> ${config_file}
    fi
  done < <(env)

  if [ "$2" == 'show-config' ]; then
    echo "# contents of ${JANUS_PROPS}"
    cat "$JANUS_PROPS"
    echo "---------------------------------------"
    echo "# contents of ${GREMLIN_YAML}"
    cat "$GREMLIN_YAML"
    exit 0
  else
    if [ "$1" == 'janusgraph' ] ; then
      # wait for storage
      if ! [ -z "${JANUS_STORAGE_TIMEOUT:-}" ]; then
        F="$(mktemp --suffix .groovy)"
        echo "graph = JanusGraphFactory.open('${JANUS_CONFIG_DIR}/janusgraph.properties')" > $F
        timeout -k 10 "${JANUS_STORAGE_TIMEOUT}s" bash -c \
          "until bin/gremlin.sh -e $F > /dev/null 2>&1; do echo \"waiting for storage...\"; sleep 5; done"
        rm -f "$F"
      fi
      echo "Starting janusgraph gremlin server"
      exec ${JANUS_HOME}/bin/gremlin-server.sh ${JANUS_CONFIG_DIR}/gremlin-server.yaml
    fi

    if [ "$1" == 'gremlin-console-remote' ] ; then
      echo "Starting gremlin remote console"
      exec ${JANUS_HOME}/bin/gremlin.sh -i scripts/remote-connect.groovy
    fi

    if [ "$1" == 'gremlin-console' ] ; then
      echo "Starting gremlin console"
      C=$(mktemp --suffix .groovy)
      echo "graph = JanusGraphFactory.open('${JANUS_CONFIG_DIR}/janusgraph.properties')" > $C
      exec ${JANUS_HOME}/bin/gremlin.sh -i $C
    fi
  fi
fi

exec "$@"
