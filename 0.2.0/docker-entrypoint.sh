#!/bin/bash

JANUS_PROPS="${JANUS_CONFIG_DIR}/janusgraph.properties"
GREMLIN_YAML="${JANUS_CONFIG_DIR}/gremlin-server.yaml"

#####################################################################################
# Write a property to the janusgraph properties file based on an environment variable
# Globals:
#   JANUS_PROPS
# Arguments:
#   1: The shorthand property name that maps to the key and environment variable template
#   2: The template key string in the form 'storage.${prop}.key'
#   3: The template key string in the form 'JANUS_STORAGE_${prop}_KEY'
# Returns:
#   None
#####################################################################################
write_prop() {
  local prop=${1}
  local template_key=${2}
  local template_env=${3}

  # generate the key name for the properties file from the template
  local key=$(sed "s/\${prop}/${prop}/" <<< ${template_key})

  # generate the environment variable name and value from the template
  local tmp=${prop//-/_}
  local var=$(sed "s/\${prop}/${tmp^^}/" <<< ${template_env})
  local val="${!var}"

  # if the line exists in the file replace it; otherwise append it
  if [ "${val}X" != "X" ]; then
    if grep -q -E "^${key}=.*" ${JANUS_PROPS}; then
      sed -ri "s/^(${key}=).*/\\1${val}/" ${JANUS_PROPS}
    else
      echo "${key}=${val}" >> ${JANUS_PROPS}
    fi
  fi

}

write_berkeley_props() {
  for prop in \
      cache-percentage \
      isolation-level \
      lock-mode \
    ; do

      write_prop ${prop} 'storage.berkeley.${prop}' 'JANUS_STORAGE_BERKELEY_${prop}'
    done
}

write_cassandra_props() {

   for prop in \
      atomic-batch-mutate \
      compaction-strategy-class \
      compaction-strategy-options \
      compression \
      compression-block-size \
      compression-type \
      frame-size-mb \
      keyspace \
      read-consistency-level \
      replication-factor \
      replication-strategy-class \
      replication-strategy-options \
      write-consistency-level \
    ; do

      write_prop ${prop} 'storage.cassandra.${prop}' 'JANUS_STORAGE_CASSANDRA_${prop}'
    done

}

write_cql_props() {

   for prop in \
      atomic-batch-mutate \
      batch-statement-size \
      cluster-name \
      compaction-strategy-class \
      compaction-strategy-options \
      compression \
      compression-block-size \
      compression-type \
      keyspace \
      local-datacenter \
      only-use-local-consistency-for-system-operations \
      protocol-version \
      read-consistency-level \
      replication-factor \
      replication-strategy-class \
      replication-strategy-options \
      write-consistency-level \
    ; do

      write_prop ${prop} 'storage.cql.${prop}' 'JANUS_STORAGE_CQL_${prop}'
    done

    write_prop "ignored" 'storage.cql.ssl.enabled' 'JANUS_STORAGE_CQL_SSL_ENABLED'
    write_prop "ignored" 'storage.cql.ssl.truststore.location' 'JANUS_STORAGE_CQL_SSL_TRUSTORE_LOCATION'
    write_prop "ignored" 'storage.cql.ssl.truststore.password' 'JANUS_STORAGE_CQL_SSL_TRUSTORE_PASSWORD'

}

write_hbase_props() {

   for prop in \
      compat-class \
      compression-algorithm \
      region-count \
      regions-per-server \
      short-cf-names \
      skip-schema-check \
      table \
    ; do

      write_prop ${prop} 'storage.hbase.${prop}' 'JANUS_STORAGE_HBASE_${prop}'
    done

}

write_storage_props() {

  for prop in \
      backend \
      batch-loading \
      buffer-size \
      connection-timeout \
      directory \
      hostname \
      page-size \
      parallel-backend-ops \
      password \
      port \
      read-only \
      read-time \
      setup-wait \
      transactions \
      username \
      write-time \
    ; do
      write_prop ${prop} 'storage.${prop}' 'JANUS_STORAGE_${prop}'
    done
    
    case "${JANUS_STORAGE_BACKEND}" in
    "berkeleyje")
        write_berkeley_props
       ;;
    "cassandra")
        write_cassandra_props
       ;;
    "cql")
       write_cql_props
       ;;
    "hbase")
       write_hbase_props
       ;;
    esac

}

write_es_index_props() {

  local index_name=${1}

  for prop in \
      client-only \
      cluster-name \
      health-request-timeout \
      ignore-cluster-name \
      interface \
      load-default-node-settings \
      local-mode \
      sniff \
      ttl-interval \
    ; do

      write_prop ${prop} 'index.'"${index_name}"'.elasticsearch.${prop}' 'JANUS_INDEX_'"${index_name^^}"'_ES_${prop}'
  done

}

write_index_props() {

  local index_name=${1}

  for prop in \
      backend \
      conf-file \
      directory \
      hostname \
      index-name \
      map-name \
      max-result-set-size \
      port \
    ; do
      write_prop ${prop} 'index.'"${index_name}"'.${prop}' 'JANUS_INDEX_'"${index_name^^}"'_${prop}'
  done

  backend="JANUS_INDEX_${index_name^^}_BACKEND"
  case "${!backend}" in
  "elasticsearch")
      write_es_index_props ${index_name}
     ;;
  esac

}

writer_server_props() {

  for prop in \
      host \
      port \
      threadPoolWorker \
      gremlinPool \
      scriptEvaluationTimeout \
      serializedResponseTimeout \
      channelizer \
      threadPoolBoss \
      maxInitialLineLength \
      maxHeaderSize \
      maxChunkSize \
      maxContentLength \
      maxAccumulationBufferComponents \
      resultIterationBatchSize \
      writeBufferHighWaterMark \
      writeBufferHighWaterMark \
    ; do
      # generate env variable for prop
      local var="JANUS_GREMLIN_${prop^^}"
      # get value of environment variable
      local val="${!var}"
      # if there is a value replace it in the properties file
      if [ "$val" ]; then
        if grep -q -E '^'"${prop}"'.*' ${GREMLIN_YAML}; then
          sed -ri 's/^('"$prop"':).*/\1 '"$val"'/' ${GREMLIN_YAML}
        else
          echo "${prop}: ${val}" >> ${GREMLIN_YAML}
        fi
      fi
    done
}

# running as root; step down to run as janusgraph user
if [ "$1" == 'janusgraph' ] && [ "$(id -u)" == "0" ]; then
    mkdir -p ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
    chown -R janusgraph:janusgraph ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
    chmod 700 ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}

    exec chroot --skip-chdir --userspec janusgraph:janusgraph / "${BASH_SOURCE}" "$@"
fi

# https://gist.github.com/samizuh/a978bc530e88847c2b5d8f75cb8caee0

# running as non root user
if [ "$1" == 'janusgraph' ]; then

    mkdir -p ${JANUS_DATA_DIR}
    chown -R "$(id -u):$(id -g)" ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
    chmod 700 ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR}
    chmod -R 600 ${JANUS_CONFIG_DIR}/*

    writer_server_props
    write_storage_props

    ORIG_IFS=${IFS}
    IFS=', ' read -r -a index_names <<< "${JANUS_INDEXES}"
    IFS=${ORIG_IFS}

    for idx in ${index_names}
    do
      write_index_props ${idx}
    done

    exec ${JANUS_HOME}/bin/gremlin-server.sh ${JANUS_CONFIG_DIR}/gremlin-server.yaml
fi

exec "$@"
