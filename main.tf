terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

variable "customer" {
  type    = string
  default = "demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

resource "null_resource" "hello" {
  triggers = {
    customer    = var.customer
    environment = var.environment
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'Planning for customer=${var.customer} env=${var.environment}'"
  }
}

resource "null_resource" "config" {
  triggers = {
    customer = var.customer
  }
}

resource "null_resource" "worker" {
  depends_on = [null_resource.config]
  triggers = {
    config_id = null_resource.config.id
  }
}

output "customer" {
  value = var.customer
}

output "environment" {
  value = var.environment
}
