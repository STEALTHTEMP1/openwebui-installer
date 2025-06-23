variable "name" {
  description = "Service name"
  type        = string
  default     = "openwebui"
}

variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "subnets" {
  description = "Subnets for the service"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group for the service"
  type        = string
}

variable "container_image" {
  description = "Container image"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 512
}

variable "assign_public_ip" {
  description = "Assign public IP"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment variables for container"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
