FROM openjdk:8-jdk

ENV JANUS_VERSION=0.2.0 \
    JANUS_HOME=/opt/janusgraph \
    JANUS_CONFIG_DIR=/etc/opt/janusgraph \
    JANUS_DATA_DIR=/var/lib/janusgraph \
    JANUS_STORAGE_TIMEOUT=60 \
    JANUS_PROPS_TEMPLATE=berkeleyje-lucene \
    janusgraph.index.search.directory=/var/lib/janusgraph/index \
    janusgraph.storage.directory=/var/lib/janusgraph/data \
    gremlinserver.graph=/etc/opt/janusgraph/janusgraph.properties \
    gremlinserver.threadPoolWorker=1 \
    gremlinserver.gremlinPool=8


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
    export BERKELEYJE_LUCENE_TEMPLATE=${JANUS_HOME}/conf/gremlin-server/janusgraph-berkeleyje-lucene-server.properties && \
    cp ${JANUS_HOME}/conf/gremlin-server/janusgraph-berkeleyje-server.properties ${BERKELEYJE_LUCENE_TEMPLATE} && \
    echo "index.search.backend=lucene" >> ${BERKELEYJE_LUCENE_TEMPLATE} && \
    echo "index.search.directory=db/searchindex" >> ${BERKELEYJE_LUCENE_TEMPLATE} && \
    echo ":remote connect tinkerpop.server conf/remote.yaml" > ${JANUS_HOME}/scripts/remote-connect.groovy && \
    echo ":> g" >> ${JANUS_HOME}/scripts/remote-connect.groovy


COPY docker-entrypoint.sh /usr/local/bin/
COPY log4j-server.properties ${JANUS_HOME}/conf/gremlin-server/log4j-server.properties

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chown -R janusgraph:janusgraph ${JANUS_HOME}

EXPOSE 8182

WORKDIR ${JANUS_HOME}

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "janusgraph" ]
