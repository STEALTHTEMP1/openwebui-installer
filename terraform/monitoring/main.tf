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
  image = "prom/prometheus:v3.4.1"

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
  image = "grafana/grafana:12.0.2"

  env = ["GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}"]

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
