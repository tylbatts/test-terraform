output "vpc_ids" {
  value = {
    primary   = aws_vpc.primary.id
    secondary = aws_vpc.secondary.id
  }
}

output "eks_cluster_endpoints" {
  value = {
    app  = aws_eks_cluster.app.endpoint
    data = aws_eks_cluster.data.endpoint
  }
}

output "s3_bucket_names" {
  value = {
    logs      = aws_s3_bucket.logs.id
    backups   = aws_s3_bucket.backups.id
    artifacts = aws_s3_bucket.artifacts.id
  }
}
