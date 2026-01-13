# =============================================================================
# RDS SQL Server Database
# =============================================================================

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# RDS Instance - SQL Server Express
# -----------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-sqlserver"

  # SQL Server Express Edition
  engine         = "sqlserver-ex"
  engine_version = "15.00"
  license_model  = "license-included"

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2

  db_name  = null # SQL Server doesn't support db_name in aws_db_instance
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Maintenance and backup
  maintenance_window      = "Sun:04:00-Sun:05:00"
  backup_window           = "03:00-04:00"
  backup_retention_period = var.environment == "prod" ? 7 : 1

  # Performance and storage
  storage_type          = "gp3"
  storage_encrypted     = true
  copy_tags_to_snapshot = true

  # Availability
  multi_az = var.environment == "prod" ? true : false

  # Other settings
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot" : null
  deletion_protection       = var.environment == "prod" ? true : false

  # Performance Insights (free tier for 7 days retention)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-sqlserver"
  }
}

# -----------------------------------------------------------------------------
# SSM Parameter for Database Connection String
# -----------------------------------------------------------------------------
resource "aws_ssm_parameter" "db_connection_string" {
  name        = "/${var.project_name}/${var.environment}/database/connection-string"
  description = "SQL Server connection string for ${var.project_name}"
  type        = "SecureString"
  value       = "Server=${aws_db_instance.main.address},${aws_db_instance.main.port};Database=${var.db_name};User Id=${var.db_username};Password=${var.db_password};TrustServerCertificate=True;"

  tags = {
    Name = "${var.project_name}-${var.environment}-db-connection-string"
  }
}
