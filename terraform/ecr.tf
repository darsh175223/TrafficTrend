# =============================================================================
# ECR Repositories for Container Images
# =============================================================================

# -----------------------------------------------------------------------------
# Auth Backend Repository (.NET)
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "auth_backend" {
  name                 = "${var.project_name}-${var.environment}-auth-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-backend"
  }
}

# -----------------------------------------------------------------------------
# Python AI Backend Repository
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "python_backend" {
  name                 = "${var.project_name}-${var.environment}-python-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-python-backend"
  }
}

# -----------------------------------------------------------------------------
# Spring Boot Backend Repository
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "spring_backend" {
  name                 = "${var.project_name}-${var.environment}-spring-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-backend"
  }
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policies - Keep only recent images
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "auth_backend" {
  repository = aws_ecr_repository.auth_backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "python_backend" {
  repository = aws_ecr_repository.python_backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "spring_backend" {
  repository = aws_ecr_repository.spring_backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
