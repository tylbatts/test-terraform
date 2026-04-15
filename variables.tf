variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "customer" {
  description = "Customer slug — used to prefix resource names"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
