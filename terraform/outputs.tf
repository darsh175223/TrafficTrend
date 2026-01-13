# =============================================================================
# TrafficTrend - Terraform Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "rds_endpoint" {
  description = "RDS SQL Server endpoint"
  value       = aws_db_instance.main.address
}

output "ecr_auth_backend_url" {
  description = "ECR repository URL for Auth Backend"
  value       = aws_ecr_repository.auth_backend.repository_url
}

output "ecr_python_backend_url" {
  description = "ECR repository URL for Python AI Backend"
  value       = aws_ecr_repository.python_backend.repository_url
}

output "ecr_spring_backend_url" {
  description = "ECR repository URL for Spring Boot Backend"
  value       = aws_ecr_repository.spring_backend.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "api_endpoint" {
  description = "API endpoint URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.create_cloudfront ? aws_cloudfront_distribution.frontend[0].domain_name : null
}

output "frontend_url" {
  description = "URL to access the frontend application"
  value       = var.create_cloudfront ? "https://${aws_cloudfront_distribution.frontend[0].domain_name}" : null
}
