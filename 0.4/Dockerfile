#
# NOTE: THIS FILE IS GENERATED VIA "update.sh"
# DO NOT EDIT IT DIRECTLY; CHANGES WILL BE OVERWRITTEN.
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

FROM debian:buster-slim as builder

ARG JANUS_VERSION=0.4.1

ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph

RUN apt update -y && apt install -y gpg unzip curl && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}-hadoop2.zip -o janusgraph.zip && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}-hadoop2.zip.asc -o janusgraph.zip.asc && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/KEYS -o KEYS && \
    gpg --import KEYS && \
    gpg --batch --verify janusgraph.zip.asc janusgraph.zip && \
    unzip janusgraph.zip && \
    mv janusgraph-${JANUS_VERSION}-hadoop2 /opt/janusgraph && \
    rm -rf ${JANUS_HOME}/elasticsearch && \
    rm -rf ${JANUS_HOME}/javadocs && \
    rm -rf ${JANUS_HOME}/log && \
    rm -rf ${JANUS_HOME}/examples

COPY conf/janusgraph-berkeleyje-lucene-server.properties conf/log4j-server.properties ${JANUS_HOME}/conf/gremlin-server/
COPY scripts/remote-connect.groovy ${JANUS_HOME}/scripts/

FROM openjdk:8-jre-slim-buster

ARG CREATED=test
ARG REVISION=test
ARG JANUS_VERSION=0.4.1

ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph \
    JANUS_CONFIG_DIR=/etc/opt/janusgraph \
    JANUS_DATA_DIR=/var/lib/janusgraph \
    JANUS_SERVER_TIMEOUT=30 \
    JANUS_STORAGE_TIMEOUT=60 \
    JANUS_PROPS_TEMPLATE=berkeleyje-lucene \
    janusgraph.index.search.directory=/var/lib/janusgraph/index \
    janusgraph.storage.directory=/var/lib/janusgraph/data \
    gremlinserver.graph=/etc/opt/janusgraph/janusgraph.properties \
    gremlinserver.threadPoolWorker=1 \
    gremlinserver.gremlinPool=8

RUN groupadd -r janusgraph --gid=999 && \
    useradd -r -g janusgraph --uid=999 janusgraph && \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y krb5-user && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /docker-entrypoint-initdb.d

COPY --from=builder /opt/janusgraph/ /opt/janusgraph/

COPY docker-entrypoint.sh /usr/local/bin/
COPY load-initdb.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chmod 755 /usr/local/bin/load-initdb.sh && \
    chown -R janusgraph:janusgraph ${JANUS_HOME}

EXPOSE 8182

WORKDIR ${JANUS_HOME}

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "janusgraph" ]

LABEL org.opencontainers.image.title="JanusGraph Docker Image" \
      org.opencontainers.image.description="Official JanusGraph Docker image" \
      org.opencontainers.image.url="https://janusgraph.org/" \
      org.opencontainers.image.documentation="https://docs.janusgraph.org/v0.4/" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/JanusGraph/janusgraph-docker/" \
      org.opencontainers.image.vendor="JanusGraph" \
      org.opencontainers.image.version="${JANUS_VERSION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.license="Apache-2.0"
