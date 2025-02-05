# Atoma Interop End-to-End Tests

This simulates a real-world end-to-end test of Atoma. It is designed to test the interoperability of Atoma nodes.

This repo and tests adhere to these constraints:

1. Be reproducible for a given commit.
1. Caching is an optimization. Things should be fine without it.
1. If we have a cache hit, be fast.

## Test spec

Each implementation is run in a container and is passed parameters via
environment variables.

## Running Locally

In some cases you may want to run locally when debugging, such as modifying internal dependencies.

1. To run the test locally, you'll also need to have docker installed in order to run the redis instance. Once docker is running, you can run the following command to start the redis instance:

```bash
docker run --rm -p 6379:6379 redis:7-alpine
```

This will start a redis instance on port 6379.

1. Next, you'll need to install the dependencies and build the implementation for the test, so run the following command:

```bash
cd nodes/ && make
```

1. Then we need to build and then run the runner, so run the following command:

```bash
cd runner && npm install && npm run e2e-test
 ```

### Caching

The caching strategy is opinionated in an attempt to make things simpler and
faster. Here's how it works:

1. We cache the result of image.json in each implementation folder.
2. The cache key is derived from the hashes of the files in the implementation folder.
3. When loading from cache, if we have a cache hit, we load the image into
   docker and create the image.json file. We then call `make -o image.json` to
   allow the implementation to build any extra things from cache (e.g. JS-libp2p
   builds browser images from the same base as node). If we have a cache miss,
   we simply call `make` and build from scratch.
4. When we push the cache we use the cache-key along with the docker platform
   (arm64 vs x86_64).
