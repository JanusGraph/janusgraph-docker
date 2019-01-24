# Building and Publishing of the Docker Images

## Building

The `build-images.sh` script will build the docker images for all the Dockerfiles in the versioned
folder directories.

## Publishing

The `push-images.sh` script will push the docker images for all the versioned folders in the
repository.

Prior to publishing, you'll need to login to [Docker Hub][DH] using the `docker login` command.

[DH]: https://hub.docker.com/
