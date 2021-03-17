resource "aws_lb" "lb" {
  name                       = "${terraform.workspace}-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.elb-sg.id]
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = false
  tags = {
    Environment = terraform.workspace
  }
}

resource "aws_lb_target_group" "app" {
  name                          = "${terraform.workspace}-app"
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.vpc.id
  target_type                   = "ip"
  port                          = 8080
  deregistration_delay          = 120
  load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    path                = "/healthcheck"
    interval            = 30
    healthy_threshold   = 4
    unhealthy_threshold = 8
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 10
  }
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_target_group" "cable" {
  name                          = "${terraform.workspace}-cable"
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.vpc.id
  target_type                   = "ip"
  port                          = 3334
  deregistration_delay          = 120
  load_balancing_algorithm_type = "least_outstanding_requests"
  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 4
    unhealthy_threshold = 8
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 10
  }
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
  depends_on = [aws_lb_target_group.app]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert.certificate_arn

  dynamic "default_action" {
    for_each = var.maintenance_mode[terraform.workspace] ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  }

  dynamic "default_action" {
    for_each = var.maintenance_mode[terraform.workspace] ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = "text/html"
        message_body = file("${path.module}/data/maintenance.html")
        status_code  = "503"
      }
    }
  }

  depends_on = [aws_lb_target_group.app]
}

resource "aws_lb_listener_rule" "cable-routing-http" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cable.arn
  }

  condition {
    path_pattern {
      values = ["/cable"]
    }
  }
}

resource "aws_lb_listener_rule" "cable-routing-https" {
  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cable.arn
  }

  condition {
    path_pattern {
      values = ["/cable"]
    }
  }
}
