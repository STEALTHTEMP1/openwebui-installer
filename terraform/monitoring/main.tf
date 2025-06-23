terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_volume" "grafana_data" {
  name = "grafana-data"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "prom/prometheus:latest"

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = "${path.module}/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = "grafana/grafana:latest"

  env = ["GF_SECURITY_ADMIN_PASSWORD=admin"]

  ports {
    internal = 3000
    external = 3001
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }

  volumes {
    host_path      = "${path.module}/grafana/provisioning"
    container_path = "/etc/grafana/provisioning"
  }
}
