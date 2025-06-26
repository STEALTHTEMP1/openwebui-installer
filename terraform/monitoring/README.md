# Monitoring Module

This Terraform module deploys Prometheus and Grafana using the Docker provider.
It mirrors the configuration used in `docker-compose.monitoring.yml`.

## Usage

```hcl
module "monitoring" {
  source = "./terraform/monitoring"
}
```

Run `terraform init && terraform apply` to start the monitoring stack.
Grafana will be available at `http://localhost:3001` and Prometheus at `http://localhost:9090`.
