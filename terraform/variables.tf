# =============================================================================
# TrafficTrend - Terraform Variables
# =============================================================================

# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "traffictrend"
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# -----------------------------------------------------------------------------
# RDS Configuration
# -----------------------------------------------------------------------------
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "traffictrend_db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# ECS Configuration
# -----------------------------------------------------------------------------
variable "auth_backend_cpu" {
  description = "CPU units for Auth Backend container (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "auth_backend_memory" {
  description = "Memory for Auth Backend container in MB"
  type        = number
  default     = 1024
}

variable "auth_backend_desired_count" {
  description = "Desired number of Auth Backend tasks"
  type        = number
  default     = 2
}

variable "python_backend_cpu" {
  description = "CPU units for Python AI Backend container"
  type        = number
  default     = 1024
}

variable "python_backend_memory" {
  description = "Memory for Python AI Backend container in MB"
  type        = number
  default     = 2048
}

variable "python_backend_desired_count" {
  description = "Desired number of Python AI Backend tasks"
  type        = number
  default     = 1
}

variable "spring_backend_cpu" {
  description = "CPU units for Spring Boot Backend container"
  type        = number
  default     = 512
}

variable "spring_backend_memory" {
  description = "Memory for Spring Boot Backend container in MB"
  type        = number
  default     = 1024
}

variable "spring_backend_desired_count" {
  description = "Desired number of Spring Boot Backend tasks"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Container Image Tags
# -----------------------------------------------------------------------------
variable "auth_backend_image_tag" {
  description = "Docker image tag for Auth Backend"
  type        = string
  default     = "latest"
}

variable "python_backend_image_tag" {
  description = "Docker image tag for Python AI Backend"
  type        = string
  default     = "latest"
}

variable "spring_backend_image_tag" {
  description = "Docker image tag for Spring Boot Backend"
  type        = string
  default     = "latest"
}

# -----------------------------------------------------------------------------
# Frontend Configuration
# -----------------------------------------------------------------------------
variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "create_cloudfront" {
  description = "Whether to create CloudFront distribution for frontend"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# JWT Configuration
# -----------------------------------------------------------------------------
variable "jwt_secret" {
  description = "Secret key for JWT token generation"
  type        = string
  sensitive   = true
}

variable "jwt_issuer" {
  description = "JWT issuer"
  type        = string
  default     = "TrafficTrend"
}

variable "jwt_audience" {
  description = "JWT audience"
  type        = string
  default     = "TrafficTrendUsers"
}
