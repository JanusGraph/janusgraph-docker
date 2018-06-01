FROM openjdk:8-jdk

ENV JANUS_VERSION=0.2.0 \
    JANUS_HOME=/opt/janusgraph \
    JANUS_CONFIG_DIR=/etc/opt/janusgraph \
    JANUS_DATA_DIR=/var/lib/janusgraph \
    JANUS_INDEXES="default" \
    JANUS_INDEX_DEFAULT_BACKEND="lucene" \
    JANUS_INDEX_DEFAULT_DIRECTORY=/var/lib/janusgraph/index \
    JANUS_STORAGE_BACKEND=berkeleyje \
    JANUS_STORAGE_DIRECTORY=/var/lib/janusgraph/data \
    JANUS_GREMLIN_HOST=0.0.0.0 \
    JANUS_GREMLIN_PORT=8182 \
    JANUS_GREMLIN_THREADPOOLWORKER=1 \
    JANUS_GREMLIN_GREMLINPOOL=8


RUN groupadd -r janusgraph --gid=999 && \
    useradd -r -g janusgraph --uid=999 janusgraph && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}-hadoop2.zip -o janusgraph.zip && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}-hadoop2.zip.asc -o janusgraph.zip.asc && \
    export GNUPGHOME="$(mktemp -d)" && \
    for gpgkey in \
        41802BA8 \
        D3C95553EE39B05E350D959CA39CC3ADAEAEF36E \
    ; do \
        found=''; \
        for server in \
            ha.pool.sks-keyservers.net \
            hkp://keyserver.ubuntu.com:80 \
            hkp://p80.pool.sks-keyservers.net:80 \
            pgp.mit.edu \
        ; do \
            echo "Fetching GPG key $gpgkey from $server"; \
            gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$gpgkey" && found=yes && break; \
        done; \
        test -z "$found" && echo >&2 "error: failed to fetch GPG key $gpgkey" && exit 1; \
    done; \
    gpg --batch --verify janusgraph.zip.asc janusgraph.zip && \
    unzip janusgraph.zip && \
    mv janusgraph-${JANUS_VERSION}-hadoop2 /opt/janusgraph && \
    rm janusgraph.zip && \
    rm janusgraph.zip.asc && \
    rm -rf ${JANUS_HOME}/elasticsearch && \
    rm -rf ${JANUS_HOME}/javadocs && \
    rm -rf ${JANUS_HOME}/log && \
    rm -rf ${JANUS_HOME}/examples && \
    rm -rf ${JANUS_HOME}/conf && \
    mkdir -p ${JANUS_HOME}/conf && \
    chown -R janusgraph:janusgraph ${JANUS_HOME} && \
    mkdir -p ${JANUS_DATA_DIR} && \
    mkdir -p ${JANUS_CONFIG_DIR}

COPY docker-entrypoint.sh /usr/local/bin/
COPY janusgraph.properties ${JANUS_CONFIG_DIR}/janusgraph.properties
COPY gremlin-server.yaml ${JANUS_CONFIG_DIR}/gremlin-server.yaml
COPY log4j-server.properties ${JANUS_HOME}/conf/gremlin-server/log4j-server.properties

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chown -R janusgraph:janusgraph ${JANUS_DATA_DIR} && \
    chown -R janusgraph:janusgraph ${JANUS_CONFIG_DIR} && \
    chmod 777 ${JANUS_DATA_DIR} ${JANUS_CONFIG_DIR} && \
    chmod -R 666 ${JANUS_CONFIG_DIR}/*

EXPOSE 8182

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "janusgraph" ]
