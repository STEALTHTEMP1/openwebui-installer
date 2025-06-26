# Monitoring Module

This Terraform module deploys Prometheus and Grafana using the Docker provider.
It mirrors the configuration used in `docker-compose.monitoring.yml`.

## Usage

```hcl
module "monitoring" {
  source = "./DevOps/terraform/monitoring"
}
```

Run `terraform init && terraform apply` to start the monitoring stack.
Grafana will be available at `http://localhost:3001` and Prometheus at `http://localhost:9090`.

### Environment variables

The Grafana container reads `GF_SECURITY_ADMIN_PASSWORD` from your environment. Set this variable before applying the module or define it in a `.env` file.
