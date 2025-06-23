# Container Registry Caching

This project can pre-build Docker images and store them in a container registry to speed up local development.

## GHCR Setup

1. Enable [GitHub Container Registry](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry) for your account.
2. Create a Personal Access Token with `write:packages` scope and add it to your repository secrets as `GHCR_TOKEN` if you run the workflow outside GitHub.

## Workflow Overview

The CI workflow builds the main development images and pushes them to `ghcr.io/<OWNER>/<REPO>` after tests and lint succeed. BuildKit caching is enabled so subsequent builds reuse layers.

### Images Published

- `dev` - environment defined by `Dockerfile.dev`
- `quality` - code quality toolbox from `Dockerfile.quality`
- `ai` - AI development tools from `Dockerfile.ai`

Each image is tagged with `latest` and can be pulled using:

```bash
docker pull ghcr.io/<OWNER>/<REPO>/<name>:latest
```

## Using Cached Images

`docker-compose.dev.yml` is configured to pull these images when the `DEV_IMAGE`, `QUALITY_IMAGE`, `DOCS_IMAGE`, and `AI_IMAGE` variables are set. For example:

```bash
DEV_IMAGE=ghcr.io/myorg/openwebui-installer/dev:latest docker compose up dev-environment
```

If the variables are unset, Docker Compose builds the images locally.

## Benefits

- Faster local setup as dependencies are pre-built.
- Consistent environments between CI and local machines.


