# =============================================================================
# TrafficTrend - Infrastructure as Code (Terraform)
# =============================================================================
# This Terraform configuration provisions the complete AWS infrastructure
# for the TrafficTrend application including:
# - VPC with public/private subnets
# - ECS Fargate for containerized services (Auth Backend, Python AI Service)
# - RDS SQL Server for database
# - S3 + CloudFront for Angular frontend hosting
# - Application Load Balancer
# - ECR repositories for container images
# - CloudWatch for logging and monitoring
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use remote state storage
  # backend "s3" {
  #   bucket         = "traffictrend-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "traffictrend-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TrafficTrend"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# Data Sources
# =============================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
