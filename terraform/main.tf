terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
}

# VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.public_subnets, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group allowing access to Open WebUI port
resource "aws_security_group" "openwebui" {
  name        = "openwebui-sg"
  description = "Allow HTTP access to Open WebUI"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

module "openwebui" {
  source            = "./modules/openwebui"
  aws_region        = var.aws_region
  cluster_arn       = aws_ecs_cluster.this.arn
  subnets           = aws_subnet.public[*].id
  security_group_id = aws_security_group.openwebui.id
  container_image   = var.container_image
  container_port    = var.container_port
  desired_count     = var.desired_count
}

data "aws_availability_zones" "available" {}

output "service_name" {
  value = module.openwebui.service_name
}
