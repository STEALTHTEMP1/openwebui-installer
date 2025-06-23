# Deploying Open WebUI with Helm

This repository provides a Helm chart for running the Open WebUI container on Kubernetes.

## Prerequisites

- Kubernetes cluster (v1.22 or later)
- Helm 3 installed on your workstation

## Installing the Chart

Clone this repository and install the chart using `helm install`:

```bash
helm install openwebui ./helm-chart
```

You can override default values using `--set` or by providing a custom values file:

```bash
helm install openwebui ./helm-chart \
  --set image.tag=v0.2.1 \
  --set ollama.baseUrl=http://ollama:11434/api
```

## Configuration

Key values in `values.yaml` include:

- **image.repository** – Container image repository
- **image.tag** – Image tag to deploy
- **ollama.baseUrl** – URL to the Ollama API
- **persistence.storageClass** – Storage class for the PVC
- **secret.data** – Key/value pairs mounted as environment variables

See `helm-chart/values.yaml` for all available options and defaults.

## Uninstalling

```bash
helm uninstall openwebui
```

This removes all Kubernetes resources created by the chart.
