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
  region = var.region
}

# ---------------------------------------------------------------------------
# VPCs
# ---------------------------------------------------------------------------

resource "aws_vpc" "primary" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.customer}-primary-vpc"
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

resource "aws_vpc" "secondary" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.customer}-secondary-vpc"
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

resource "aws_subnet" "primary_public" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.customer}-primary-public-1a"
  }
}

resource "aws_subnet" "primary_private" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "${var.customer}-primary-private-1a"
  }
}

# ---------------------------------------------------------------------------
# EKS Clusters
# ---------------------------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "${var.customer}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "app" {
  name     = "${var.customer}-app-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = [aws_subnet.primary_public.id, aws_subnet.primary_private.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

  tags = {
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

resource "aws_eks_cluster" "data" {
  name     = "${var.customer}-data-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = [aws_subnet.primary_public.id, aws_subnet.primary_private.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

  tags = {
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

# ---------------------------------------------------------------------------
# S3 Buckets
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  bucket = "${var.customer}-logs-${var.environment}"
  tags = {
    Purpose     = "Application logs"
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "${var.customer}-backups-${var.environment}"
  tags = {
    Purpose     = "Database backups"
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.customer}-artifacts-${var.environment}"
  tags = {
    Purpose     = "Build artifacts"
    Environment = var.environment
    ManagedBy   = "aether"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
