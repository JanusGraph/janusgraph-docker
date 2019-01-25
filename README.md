# JanusGraph Docker images

This repository contains the [JanusGraph][JG] docker images.

## Usage

### Start a JanusGraph Server instance

The default configuration uses the [Oracle Berkeley DB Java Edition][JG_BDB] storage backend
and the [Apache Lucene][JG_LUCENE] indexing backend

```bash
docker run --name janusgraph-default janusgraph/janusgraph:latest
```

### Connecting with Gremlin Console

Start a JanusGraph container and connect to the `janusgraph` server remotely using Gremlin Console

```bash
$ docker run --rm --link janusgraph-default:janusgraph -e GREMLIN_REMOTE_HOSTS=janusgraph \
    -it janusgraph/janusgraph:latest ./bin/gremlin.sh

         \,,,/
         (o o)
-----oOOo-(3)-oOOo-----
plugin activated: janusgraph.imports
plugin activated: tinkerpop.server
plugin activated: tinkerpop.utilities
plugin activated: tinkerpop.hadoop
plugin activated: tinkerpop.spark
plugin activated: tinkerpop.tinkergraph
gremlin> :remote connect tinkerpop.server conf/remote.yaml
==>Configured janusgraph/172.17.0.2:8182
gremlin> :> g.addV('person').property('name', 'chris')
==>v[4160]
gremlin> :> g.V().values('name')
==>chris
```

### Using Docker Compose

Start a JanusGraph Server instance using [docker-compose.yml](docker-compose.yml)

```bash
docker-compose -f docker-compose.yml up
```

Start a JanusGraph container running Gremlin Console in the same network using
[docker-compose.yml](docker-compose.yml)

```bash
docker-compose -f docker-compose.yml run --rm -e GREMLIN_REMOTE_HOSTS=janusgraph janusgraph ./bin/gremlin.sh
```

## Configuration

The JanusGraph image provides multiple methods for configuration, including using environment
variables to set options and using bind-mounted configuration.

### Docker environment variables

The environment variables supported by the JanusGraph image are summarized below.

| Variable | Description |
| ---- | ---- |
| JANUS_PROPS_TEMPLATE | JanusGraph properties file template (see [below](#properties-template)). The default properties file template is `berkeleyje-lucene`. |
| janusgraph.* | Any JanusGraph configuration option to override in the template properties file, specified with an outer `janusgraph` namespace (e.g. janusgraph.storage.hostname). See [JanusGraph Configuration][JG_CONFIG] for available options. |
| gremlinserver.* | Any Gremlin Server configuration option to override in the default configuration (yaml) file, specified with an outer `gremlinserver` namespace (e.g. gremlinserver.threadPoolWorker). See [Gremlin Server Configuration][GS_CONFIG] for available options. |
| JANUS_STORAGE_TIMEOUT | Timeout (seconds) used when waiting for the storage backend before starting Gremlin Server. Default value is 60 seconds. |
| GREMLIN_REMOTE_HOSTS | Optional hostname for external Gremlin Server instance. Enables a container running Gremlin Console to connect to a remote server using `conf/remote.yaml`. |

#### Properties template

The `JANUS_PROPS_TEMPLATE` environment variable is used to define the base JanusGraph
properties file. Values in the template properties file are used unless an alternate value
for a given property is provided in the environment. The common usage will be to specify 
a template for the general environment (e.g. cassandra-es) and then provide additional 
individual configuration to override/extend the template. The available templates depend 
on the JanusGraph version (see [conf/gremlin-server/janusgraph*.properties][JG_TEMPLATES]).

| JANUS_PROPS_TEMPLATE | Supported Versions |
| ----- | ----- |
| berkeleyje | all |
| berkeleyje-es | all |
| berkeleyje-lucene (default) | all |
| cassandra-es | all |
| cql-es | >=0.2.1 |

##### Example: Berkeleyje-Lucene

Start a JanusGraph instance using the default `berkeleyje-lucene` template with custom
storage and server settings

```bash
docker run --name janusgraph-default \
    -e janusgraph.storage.berkeleyje.cache-percentage=80 \
    -e gremlinserver.threadPoolWorker=2 \
    janusgraph/janusgraph:latest
```

Inspect configuration

```bash
$ docker exec janusgraph-default sh -c 'cat /etc/opt/janusgraph/janusgraph.properties | grep ^[a-z]'
gremlin.graph=org.janusgraph.core.JanusGraphFactory
storage.backend=berkeleyje
storage.directory=/var/lib/janusgraph/data
index.search.backend=lucene
storage.berkeleyje.cache-percentage=80
index.search.directory=/var/lib/janusgraph/index

$ docker exec janusgraph-default grep threadPoolWorker /etc/opt/janusgraph/gremlin-server.yaml
threadPoolWorker: 2
```

##### Example: Cassandra-ES with Docker Compose

Start a JanusGraph instance with Cassandra and Elasticsearch using the `cassandra-es`
template through [docker-compose-cql-es.yml](docker-compose-cql-es.yml)

```bash
docker-compose -f docker-compose-cql-es.yml up
```

Inspect configuration using [docker-compose-cql-es.yml](docker-compose-cql-es.yml)

```bash
$ docker-compose -f docker-compose-cql-es.yml exec janusgraph sh -c 'cat /etc/opt/janusgraph/janusgraph.properties | grep ^[a-z]'
gremlin.graph=org.janusgraph.core.JanusGraphFactory
storage.backend=cql
storage.hostname=jce-cassandra
cache.db-cache = true
cache.db-cache-clean-wait = 20
cache.db-cache-time = 180000
cache.db-cache-size = 0.25
index.search.backend=elasticsearch
index.search.hostname=jce-elastic
index.search.elasticsearch.client-only=true
storage.directory=/var/lib/janusgraph/data
index.search.directory=/var/lib/janusgraph/index
```

### Mounted Configuration

By default, the container stores both the `janusgraph.properties` and `gremlin-server.yaml` files
in the `JANUS_CONFIG_DIR` directory which maps to `/etc/opt/janusgraph`. When the container
starts, it updates those files using the environment variable values. If you have a specific
configuration and do not wish to use environment variables to configure JanusGraph, you can
mount a directory containing your own version of those configuration files into the container
through a bind mount e.g. `-v /local/path/on/host:/etc/opt/janusgraph:ro`. You'll need to bind
the files as read only however if you do not wish to have the environment variables override the 
values in that file.

#### Example with mounted configuration

Start a JanusGraph instance with mounted configuration using [docker-compose-mount.yml](docker-compose-mount.yml)

```bash
$ docker-compose -f docker-compose-mount.yml up
janusgraph-mount | chown: changing ownership of '/etc/opt/janusgraph/janusgraph.properties': Read-only file system
...
```

## Community

JanusGraph.Net uses the same communication channels as JanusGraph in general.
So, please refer to the
[_Community_ section in JanusGraph's main repository][JG_COMMUNITY]
for more information about these various channels.

Please use GitHub issues only to report bugs or request features.

## Contributing

Please see
[`CONTRIBUTING.md` in JanusGraph's main repository][JG_CONTRIBUTING]
for more information, including CLAs and best practices for working with
GitHub.

## License

JanusGraph Docker images are provided under the [Apache 2.0
license](APACHE-2.0.txt) and documentation is provided under the [CC-BY-4.0
license](CC-BY-4.0.txt). For details about this dual-license structure, please
see [`LICENSE.txt`](LICENSE.txt).

[JG]: http://janusgraph.org/
[JG_BDB]: https://docs.janusgraph.org/latest/bdb.html
[JG_CONFIG]: https://docs.janusgraph.org/latest/config-ref.html
[JG_LUCENE]: https://docs.janusgraph.org/latest/lucene.html
[JG_TEMPLATES]: https://github.com/search?q=org:JanusGraph+repo:janusgraph+filename:janusgraph.properties%20path:janusgraph-dist/src/assembly/static/conf/gremlin-server
[GS_CONFIG]: http://tinkerpop.apache.org/docs/current/reference/#_configuring_2
[DH]: https://hub.docker.com/
[JG_COMMUNITY]: https://github.com/JanusGraph/janusgraph#community
[JG_CONTRIBUTING]: https://github.com/JanusGraph/janusgraph/blob/master/CONTRIBUTING.md
