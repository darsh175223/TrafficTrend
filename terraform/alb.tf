# =============================================================================
# Application Load Balancer
# =============================================================================

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# -----------------------------------------------------------------------------
# Target Groups
# -----------------------------------------------------------------------------
resource "aws_lb_target_group" "auth_backend" {
  name        = "${var.project_name}-${var.environment}-auth-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-backend-tg"
  }
}

resource "aws_lb_target_group" "python_backend" {
  name        = "${var.project_name}-${var.environment}-py-tg"
  port        = 5002
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-python-backend-tg"
  }
}

resource "aws_lb_target_group" "spring_backend" {
  name        = "${var.project_name}-${var.environment}-spring-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-backend-tg"
  }
}

# -----------------------------------------------------------------------------
# HTTP Listener (redirects to HTTPS in production)
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\": \"healthy\", \"service\": \"TrafficTrend API\"}"
      status_code  = "200"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

# -----------------------------------------------------------------------------
# Listener Rules - Path-based routing
# -----------------------------------------------------------------------------
resource "aws_lb_listener_rule" "auth_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/Auth/*", "/api/Survey/*", "/health"]
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-rule"
  }
}

resource "aws_lb_listener_rule" "python_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.python_backend.arn
  }

  condition {
    path_pattern {
      values = ["/ai/*", "/forecast/*", "/predict/*", "/staffing/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-python-rule"
  }
}

resource "aws_lb_listener_rule" "spring_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spring_backend.arn
  }

  condition {
    path_pattern {
      values = ["/spring/*", "/actuator/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-spring-rule"
  }
}
