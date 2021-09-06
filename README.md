# JanusGraph Docker images

[![GitHub Workflow Status][actions-badge]][actions-url]
[![Docker pulls][docker-pulls-img]][docker-hub-url]

This repository contains build scripts and configuration files for the official
[JanusGraph][JG] Docker images, which are published on the [Docker Hub][docker-hub-url].

> **Note:** even though the examples below and in the Docker Compose config
> files (`*.yml`) use the `latest` image, when running a service in production,
> be sure to specify a specific numeric version to
> [avoid](https://medium.com/@mccode/the-misunderstood-docker-tag-latest-af3babfd6375)
> [unexpected](https://github.com/hadolint/hadolint/wiki/DL3007)
> [behavior changes](https://vsupalov.com/docker-latest-tag/)
> due to `latest` pointing to a new release version, see our [Docker tagging Policy](#docker-tagging-policy).

## Usage

### Start a JanusGraph Server instance

The default configuration uses the [Oracle Berkeley DB Java Edition][JG_BDB] storage backend
and the [Apache Lucene][JG_LUCENE] indexing backend:

```bash
docker run --rm --name janusgraph-default docker.io/janusgraph/janusgraph:latest
```

### Connecting with Gremlin Console

Start a JanusGraph container and connect to the `janusgraph` server remotely
using Gremlin Console:

```bash
$ docker run --rm --link janusgraph-default:janusgraph -e GREMLIN_REMOTE_HOSTS=janusgraph \
    -it docker.io/janusgraph/janusgraph:latest ./bin/gremlin.sh

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

Start a JanusGraph Server instance using [`docker-compose.yml`](docker-compose.yml):

```bash
docker-compose -f docker-compose.yml up
```

Start a JanusGraph container running Gremlin Console in the same network using
[`docker-compose.yml`](docker-compose.yml):

```bash
docker-compose -f docker-compose.yml run --rm \
    -e GREMLIN_REMOTE_HOSTS=janusgraph janusgraph ./bin/gremlin.sh
```

### Initialization

When the container is started it will execute files with the extension
`.groovy` that are found in `/docker-entrypoint-initdb.d` with the
Gremlin Console.
These scripts are only executed after the JanusGraph Server instance was
started.
So, they can [connect to it][JG_CONNECT_JAVA] and execute Gremlin traversals.

For example, to add a vertex to the graph, create a file
`/docker-entrypoint-initdb.d/add-vertex.groovy` with the following content:

```groovy
g = traversal().withRemote('conf/remote-graph.properties')
g.addV('demigod').property('name', 'hercules').iterate()
```

### Generate Config

JanusGraph-Docker has a single utility method. This method writes the JanusGraph Configuration and show the config afterward.

```bash
docker run --rm -it docker.io/janusgraph/janusgraph:latest janusgraph show-config
```

**Default config locations are `/etc/opt/janusgraph/janusgraph.properties` and `/etc/opt/janusgraph/janusgraph-server.yaml`.**

## Configuration

The JanusGraph image provides multiple methods for configuration, including using environment
variables to set options and using bind-mounted configuration.

### Docker environment variables

The environment variables supported by the JanusGraph image are summarized below.

| Variable | Description | Default |
| ---- | ---- | ---- |
| `JANUS_PROPS_TEMPLATE` | JanusGraph properties file template (see [below](#properties-template)). |`berkeleyje-lucene` |
| `janusgraph.*` | Any JanusGraph configuration option to override in the template properties file, specified with an outer `janusgraph` namespace (e.g., `janusgraph.storage.hostname`). See [JanusGraph Configuration][JG_CONFIG] for available options. | no default value | 
| `gremlinserver.*` | Any Gremlin Server configuration option to override in the default configuration (YAML) file, specified with an outer `gremlinserver` namespace (e.g., `gremlinserver.threadPoolWorker`). You can set or update nested options using additional dots (e.g., `gremlinserver.graphs.graph`). See [Gremlin Server Configuration][GS_CONFIG] for available options. See [Gremlin Server Environment Variable Syntax](#Gremlin-Server-Environment-Variable-Syntax) section below for help editing gremlin server configuration using environment variables. | no default value` | 
| `JANUS_SERVER_TIMEOUT` | Timeout (seconds) used when waiting for Gremlin Server before executing initialization scripts. | `30` |
| `JANUS_STORAGE_TIMEOUT` | Timeout (seconds) used when waiting for the storage backend before starting Gremlin Server. | `60` |
| `GREMLIN_REMOTE_HOSTS` | Optional hostname for external Gremlin Server instance. Enables a container running Gremlin Console to connect to a remote server using `conf/remote.yaml`. | no default value | 
| `JANUS_INITDB_DIR` | Defines the location of the initialization scripts.  | `/docker-entrypoint-initdb.d` |

#### Properties template

The `JANUS_PROPS_TEMPLATE` environment variable is used to define the base JanusGraph
properties file. Values in the template properties file are used unless an alternate value
for a given property is provided in the environment. The common usage will be to specify
a template for the general environment (e.g., `cassandra-es`) and then provide additional
individual configuration to override/extend the template. The available templates depend
on the JanusGraph version (see [`conf/janusgraph*.properties`][JG_TEMPLATES]).

| `JANUS_PROPS_TEMPLATE` | Supported Versions |
| ----- | ----- |
| `berkeleyje` | all |
| `berkeleyje-es` | all |
| `berkeleyje-lucene` (default) | all |
| `cassandra-es` | <=0.5.3 |
| `cql-es` | >=0.2.1 |
| `cql` | >=0.5.3 |
| `inmemory` | >=0.5.3 |

##### Example: Berkeleyje-Lucene

Start a JanusGraph instance using the default `berkeleyje-lucene` template with custom
storage and server settings:

```bash
docker run --name janusgraph-default \
    -e janusgraph.storage.berkeleyje.cache-percentage=80 \
    -e gremlinserver.threadPoolWorker=2 \
    docker.io/janusgraph/janusgraph:latest
```

Inspect the configuration:

```bash
$ docker exec janusgraph-default sh -c 'cat /etc/opt/janusgraph/janusgraph.properties | grep ^[a-z]'
gremlin.graph=org.janusgraph.core.JanusGraphFactory
storage.backend=berkeleyje
storage.directory=/var/lib/janusgraph/data
index.search.backend=lucene
storage.berkeleyje.cache-percentage=80
index.search.directory=/var/lib/janusgraph/index

$ docker exec janusgraph-default grep threadPoolWorker /etc/opt/janusgraph/janusgraph-server.yaml
threadPoolWorker: 2
```

##### Example: Cassandra-ES with Docker Compose

Start a JanusGraph instance with Cassandra and Elasticsearch using the `cql-es`
template through [`docker-compose-cql-es.yml`](docker-compose-cql-es.yml):

```bash
docker-compose -f docker-compose-cql-es.yml up
```

Inspect the configuration using
[`docker-compose-cql-es.yml`](docker-compose-cql-es.yml):

```bash
$ docker-compose -f docker-compose-cql-es.yml exec \
      janusgraph sh -c 'cat /etc/opt/janusgraph/janusgraph.properties | grep ^[a-z]'
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

#### Gremlin Server Environment Variable Syntax

Environment Variables that start with the prefix `gremlinserver.` or `gremlinserver%d.` are used
to edit the base janusgraph-server.yaml file. The text after the prefix in the environment variable
name should follow a specific syntax. This syntax is implemented using the [yq][YQ_GITHUB] write and
delete commands and the [yq documentation][YQ_DOC] can be used as a reference for this syntax.
Secondly, the value of the environment variable will be used to set the value of the key specified
in the environment variable name.

Let's take a look at a few examples:

##### Nested Properties

For example, say we want to add a configuration property `graphs.ConfigurationMangementGraph`
with the value `conf/JanusGraph-configurationmanagement.properties`:

```text
$ docker run --rm -it -e gremlinserver.graphs.ConfigurationManagementGraph=\
conf/JanusGraph-configurationmanagement.properties docker.io/janusgraph/janusgraph:latest janusgraph show-config
...
graphs:
  graph: conf/janusgraph-cql-es-server.properties
  ConfigurationManagementGraph: conf/JanusGraph-configurationmanagement.properties
scriptEngines:
...
```

##### Delete a component

To delete a component append %d to the 'gremlinserver.' prefix before the closing dot and then
select the component following the prefix. Don't forget the trailing '='. For example to delete the
graphs.graph configuration property we can do the following:

```text
$ docker run --rm -it -e gremlinserver%d.graphs.graph= docker.io/janusgraph/janusgraph:latest janusgraph show-config
...
channelizer: org.apache.tinkerpop.gremlin.server.channel.WebSocketChannelizer
graphs: {}
scriptEngines:
...
```

##### Append item and alternate indexing syntax

This example shows how to append an item to a list. This can be done by adding "[+]" at the end of
the environment variable name. This example also shows how to use square bracket syntax as an
alternative to the dot syntax. This alternate syntax is useful if one of the keys in the property
path contains special characters as we see in the example below.

```text
$ docker run --rm -it -e gremlinserver.scriptEngines.gremlin-groovy\
.plugins["org.apache.tinkerpop.gremlin.jsr223.ScriptFileGremlinPlugin"]\
.files[+]=/scripts/another-script.groovy docker.io/janusgraph/janusgraph:latest janusgraph show-config
...
scriptEngines:
  gremlin-groovy:
    plugins:
      org.janusgraph.graphdb.tinkerpop.plugin.JanusGraphGremlinPlugin: {}
      org.apache.tinkerpop.gremlin.server.jsr223.GremlinServerGremlinPlugin: {}
      org.apache.tinkerpop.gremlin.tinkergraph.jsr223.TinkerGraphGremlinPlugin: {}
      org.apache.tinkerpop.gremlin.jsr223.ImportGremlinPlugin:
        classImports:
        - java.lang.Math
        methodImports:
        - java.lang.Math#*
      org.apache.tinkerpop.gremlin.jsr223.ScriptFileGremlinPlugin:
        files:
        - scripts/empty-sample.groovy
        - /scripts/another-script.groovy
...
```

### Mounted Configuration

By default, the container stores both the `janusgraph.properties` and `janusgraph-server.yaml` files
in the `JANUS_CONFIG_DIR` directory which maps to `/etc/opt/janusgraph`. When the container
starts, it updates those files using the environment variable values. If you have a specific
configuration and do not wish to use environment variables to configure JanusGraph, you can
mount a directory containing your own version of those configuration files into the container
through a bind mount, e.g., `-v /local/path/on/host:/etc/opt/janusgraph:ro`. You'll need to bind
the files as read-only, however, if you do not wish to have the environment variables override the
values in that file.

#### Example with mounted configuration

Start a JanusGraph instance with mounted configuration using
[`docker-compose-mount.yml`](docker-compose-mount.yml):

```bash
$ docker-compose -f docker-compose-mount.yml up
janusgraph-mount | chown: changing ownership of '/etc/opt/janusgraph/janusgraph.properties': Read-only file system
...
```

## Default user JanusGraph

> **Note:** The default user of the image changed for all version beginning with the newest image version of 0.5.3.

The user is created with uid 999 and gid 999 and user's a home dir is `/var/lib/janusgraph`. 

Folloing folder are created with these user rights:
* `/var/lib/janusgraph`
* `/etc/opt/janusgraph`
* `/opt/janusgraph`
* `/docker-entrypoint-initdb.d`

## Docker Tagging Policy

Here's the policy we follow for tagging our Docker images:

| Tag            | Support level | Docker base image |
|:--------------|:-------------|---|
| latest         | <ul><li>latest JanusGraph release</li><li>no breaking changes guarantees</li></ul> | openjdk:8-jre-slim-buster |
| 0.x            | <ul><li>newest patch-level version of JanusGraph</li><li>expect breaking changes</li></ul> | openjdk:8-jre-slim-buster |
| 0.x.x          | <ul><li>defined JanusGraph version</li><li>breaking changes are only in this repo</li></ul> | openjdk:8-jre-slim-buster |
| 0.x.x-revision | <ul><li>defined JanusGraph version</li><li>defined commit in JanusGraph-docker repo</li></ul> | openjdk:8-jre-slim-buster |

We collect a list of changes in our docker images build process in our [CHANGELOG.md](./CHANGELOG.md)

## Community

JanusGraph-Docker uses the same communication channels as JanusGraph in general.
Please refer to the
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

[actions-badge]: https://img.shields.io/github/workflow/status/JanusGraph/janusgraph-docker/Deploy%20Images
[actions-url]: https://github.com/JanusGraph/janusgraph-docker/actions
[docker-pulls-img]: https://img.shields.io/docker/pulls/janusgraph/janusgraph.svg
[docker-hub-url]: https://hub.docker.com/r/janusgraph/janusgraph
[JG]: https://janusgraph.org/
[JG_BDB]: https://docs.janusgraph.org/storage-backend/bdb/
[JG_CONFIG]: https://docs.janusgraph.org/basics/configuration-reference/
[JG_LUCENE]: https://docs.janusgraph.org/index-backend/lucene/
[JG_CONNECT_JAVA]: https://docs.janusgraph.org/connecting/java/
[JG_TEMPLATES]: https://github.com/search?q=org:JanusGraph+repo:janusgraph+filename:janusgraph.properties%20path:janusgraph-dist/src/assembly/static/conf/gremlin-server
[GS_CONFIG]: http://tinkerpop.apache.org/docs/current/reference/#_configuring_2
[YQ_GITHUB]: https://github.com/mikefarah/yq
[YQ_DOC]: https://mikefarah.gitbook.io/yq
[DH]: https://hub.docker.com/
[JG_COMMUNITY]: https://github.com/JanusGraph/janusgraph#community
[JG_CONTRIBUTING]: https://github.com/JanusGraph/janusgraph/blob/master/CONTRIBUTING.md
