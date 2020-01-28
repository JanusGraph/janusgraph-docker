# Building and Publishing of the Docker Images

## Building

The `build-images.sh` script will build the docker images for all the Dockerfiles in the versioned
folder directories.

```bash
./build-images.sh
```

Optionally build a specific version

```bash
./build-images.sh 0.4
```

## Deployment

We use continuous deployment via Travis CI to push images to Docker Hub.
Every commit on `master` automatically triggers a deployment.

Travis CI simply executes the `push-images.sh` script which will push the docker images for all the versioned folders
in the repository.

## Updating and adding versions

The `update.sh` script will update the Dockerfile in the relevant versioned folder directory to the provided version.

```bash
./update.sh 0.4.1
```

Alternatively the script will automatically determine the latest version using the GitHub Releases API (requires
[jq](https://stedolan.github.io/jq/)).

```bash
./update 0.3
```

If the versioned folder directory does not exist it will be created and initialized with the resources from the
`build` directory and the Dockerfile will be updated as described above.

```bash
./update.sh 0.4
```

Finally if no argument is provided then the Dockerfiles in all versioned directories will be updated to the relevant
latest version using the GitHub Releases API (requires [jq](https://stedolan.github.io/jq/)).

```bash
./update.sh
```

[DH]: https://hub.docker.com/
