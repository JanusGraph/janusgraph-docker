<<<<<<< HEAD
# JanusGraph Docker images

Repository for building and publishing [JanusGraph][JG] docker images.

## License

JanusGraph Docker images are provided under the [Apache 2.0
license](APACHE-2.0.txt) and documentation is provided under the [CC-BY-4.0
license](CC-BY-4.0.txt). For details about this dual-license structure, please
see [`LICENSE.txt`](LICENSE.txt).

## Building ##

The `build-images.sh` script will build the docker images for all the Dockerfiles in the versioned
folder directories.

## Publishing ##

The `push-images.sh` script will push the docker images for all the versioned folders in the repo.

Prior to publishing, you'll need to login to [Docker Hub][DH] using the `docker login` command.

## Configuration ##

The docker containers are configured through environment variables. The environment variables are 
structured to reflect the different configuration properties available in the 
[JanusGraph Configuration][JG_CONFIG] .

**Example**

| Configuration Key       | Environment Variable        |
| ----------------------- | --------------------------- |
| storage.backend         | JANUS_STORAGE_BACKEND       |
| storage.cql.keyspace    | JANUS_STORAGE_CQL_KEYSPACE  |
| index.search.backend    | JANUS_INDEX_SEARCH_BACKEND  |


In general, a configuration parameter of the form `chained.property.path` will take the form
`JANUS_CHAINED_PROPERTY_PATH`. The environment variable will be prefixed with `JANUS` and the 
hyphens and periods in the name of the property key are replaced with underscores. Lastly, the
characters in the property path are converted to uppercase.

### Mounted Configuration ###

By default, the container stores both the janusgraph.properties and gremlin-server.yaml files
in the `JANUS_CONFIG_DIR` directory which maps to `/etc/opt/janusgraph`. When the container
starts, it updates those files using the environment variable values. If you have a specific
configuration and do not wish to use environment variables to configure JanusGraph, you can 
mount a directory containing your own version of those configuration files into the container
through a bind mount e.g. `-v /local/path/on/host:/etc/opt/janusgraph:ro`. You'll need to bind
the files as read only however if you do not wish to have the environment variables override the 
values in that file. See the `docker-compose-mount.yml` file for an example.

## Running ##

There are `docker-compose.yml` files demonstrating various configurations in which the JanusGraph
image can be used. 


[JG]: http://janusgraph.org/
[JG_CONFIG]: https://docs.janusgraph.org/latest/config-ref.html
[DH]: https://hub.docker.com/
