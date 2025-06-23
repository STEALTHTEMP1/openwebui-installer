# Open WebUI Helm Chart

This directory contains a Helm chart for deploying Open WebUI.

## Prerequisites
- Kubernetes 1.20+
- Helm 3.x

## Installation

```bash
helm repo add openwebui https://example.com/charts
helm install my-webui helm-chart/openwebui \
  --set env.secretKey="$(openssl rand -hex 16)"
```

Values can also be customised by editing `values.yaml` or passing `--set key=value`.

## Values Reference

| Key | Description | Default |
|-----|-------------|---------|
| `image.repository` | Container image repository | `ghcr.io/open-webui/open-webui` |
| `image.tag` | Image tag | `main` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `env.OLLAMA_BASE_URL` | URL for Ollama backend | `http://ollama:11434` |
| `env.secretKey` | Secret key for the application | `""` |
| `persistence.enabled` | Enable persistent volume | `true` |
| `persistence.storageClass` | Storage class to use | `""` |
| `persistence.size` | PVC size | `5Gi` |

## Uninstall

```bash
helm uninstall my-webui
```
