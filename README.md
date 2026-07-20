# geoflow-api

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Build Status](https://github.com/r-geoflow/geoflow-api/actions/workflows/docker-build-image.yaml/badge.svg?branch=main)](https://github.com/r-geoflow/geoflow-api/actions/workflows/docker-build-image.yaml)
[![Github_Status_Badge](https://img.shields.io/badge/Github-1.0.0--RC1-blue.svg)](https://github.com/r-geoflow/geoflow-api)

The `geoflow-api` provides a way to run the [geoflow](https://github.com/r-geoflow/geoflow-api) as web API. The image exposes the `geoflow::executeWorkflow` main R function used to execute geoflows from a configuration file (JSON or YAML).

## Pull the `geoflow-api` Docker image

```
docker pull ghcr.io/r-geoflow/geoflow-api:latest
```

## Launch the `geoflow-api`

```
docker run -p 8000:8000 ghcr.io/r-geoflow/geoflow-api:latest
```
