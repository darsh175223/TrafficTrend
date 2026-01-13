# =============================================================================
# ECS Cluster and Services
# =============================================================================

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "auth_backend" {
  name              = "/ecs/${var.project_name}/${var.environment}/auth-backend"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "python_backend" {
  name              = "/ecs/${var.project_name}/${var.environment}/python-backend"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-${var.environment}-python-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "spring_backend" {
  name              = "/ecs/${var.project_name}/${var.environment}/spring-backend"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-backend-logs"
  }
}

# -----------------------------------------------------------------------------
# ECS Task Execution Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "${var.project_name}-${var.environment}-ecs-ssm-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# ECS Task Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# -----------------------------------------------------------------------------
# Auth Backend Task Definition
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "auth_backend" {
  family                   = "${var.project_name}-${var.environment}-auth-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.auth_backend_cpu
  memory                   = var.auth_backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "auth-backend"
      image     = "${aws_ecr_repository.auth_backend.repository_url}:${var.auth_backend_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = var.environment == "prod" ? "Production" : "Development"
        },
        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:5000"
        },
        {
          name  = "Jwt__Issuer"
          value = var.jwt_issuer
        },
        {
          name  = "Jwt__Audience"
          value = var.jwt_audience
        },
        {
          name  = "PythonBackendUrl"
          value = "http://localhost:5002"
        }
      ]

      secrets = [
        {
          name      = "ConnectionStrings__DefaultConnection"
          valueFrom = aws_ssm_parameter.db_connection_string.arn
        },
        {
          name      = "Jwt__Key"
          valueFrom = aws_ssm_parameter.jwt_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.auth_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-backend-task"
  }
}

# -----------------------------------------------------------------------------
# Python AI Backend Task Definition
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "python_backend" {
  family                   = "${var.project_name}-${var.environment}-python-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.python_backend_cpu
  memory                   = var.python_backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "python-backend"
      image     = "${aws_ecr_repository.python_backend.repository_url}:${var.python_backend_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 5002
          hostPort      = 5002
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "FLASK_ENV"
          value = var.environment == "prod" ? "production" : "development"
        },
        {
          name  = "PORT"
          value = "5002"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.python_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5002/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-python-backend-task"
  }
}

# -----------------------------------------------------------------------------
# Spring Boot Backend Task Definition
# -----------------------------------------------------------------------------
resource "aws_ecs_task_definition" "spring_backend" {
  family                   = "${var.project_name}-${var.environment}-spring-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.spring_backend_cpu
  memory                   = var.spring_backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "spring-backend"
      image     = "${aws_ecr_repository.spring_backend.repository_url}:${var.spring_backend_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "SERVER_PORT"
          value = "8080"
        },
        {
          name  = "PYTHON_BACKEND_URL"
          value = "http://localhost:5002"
        }
      ]

      secrets = [
        {
          name      = "SPRING_DATASOURCE_URL"
          valueFrom = aws_ssm_parameter.spring_db_url.arn
        },
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = aws_ssm_parameter.db_username.arn
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = aws_ssm_parameter.jwt_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.spring_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 90
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-backend-task"
  }
}

# -----------------------------------------------------------------------------
# Additional SSM Parameters
# -----------------------------------------------------------------------------
resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.project_name}/${var.environment}/jwt/secret"
  description = "JWT secret key"
  type        = "SecureString"
  value       = var.jwt_secret

  tags = {
    Name = "${var.project_name}-${var.environment}-jwt-secret"
  }
}

resource "aws_ssm_parameter" "spring_db_url" {
  name        = "/${var.project_name}/${var.environment}/spring/datasource-url"
  description = "Spring Boot JDBC URL"
  type        = "SecureString"
  value       = "jdbc:sqlserver://${aws_db_instance.main.address}:${aws_db_instance.main.port};database=${var.db_name};encrypt=true;trustServerCertificate=true"

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-db-url"
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment}/database/username"
  description = "Database username"
  type        = "SecureString"
  value       = var.db_username

  tags = {
    Name = "${var.project_name}-${var.environment}-db-username"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/${var.environment}/database/password"
  description = "Database password"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name = "${var.project_name}-${var.environment}-db-password"
  }
}

# -----------------------------------------------------------------------------
# ECS Services
# -----------------------------------------------------------------------------
resource "aws_ecs_service" "auth_backend" {
  name            = "${var.project_name}-${var.environment}-auth-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth_backend.arn
  desired_count   = var.auth_backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_backend.arn
    container_name   = "auth-backend"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-backend-service"
  }
}

resource "aws_ecs_service" "python_backend" {
  name            = "${var.project_name}-${var.environment}-python-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.python_backend.arn
  desired_count   = var.python_backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.python_backend.arn
    container_name   = "python-backend"
    container_port   = 5002
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-${var.environment}-python-backend-service"
  }
}

resource "aws_ecs_service" "spring_backend" {
  name            = "${var.project_name}-${var.environment}-spring-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.spring_backend.arn
  desired_count   = var.spring_backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.spring_backend.arn
    container_name   = "spring-backend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-backend-service"
  }
}
