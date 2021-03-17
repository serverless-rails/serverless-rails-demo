resource "aws_security_group" "ssh-sg" {
  name        = "${terraform.workspace}-ssh-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 2222
    to_port     = 2222
    cidr_blocks = var.ssh_ips[terraform.workspace]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-ssh-sg"
  }
}

resource "aws_security_group" "elb-sg" {
  name        = "${terraform.workspace}-elb-sg"
  description = "Inbound traffic to ELB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-elb-sg"
  }
}

resource "aws_security_group" "ecs-sg" {
  name        = "${terraform.workspace}-ecs-sg"
  description = "Inbound traffic to ECS"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "${terraform.workspace}-ecs-sg"
  }
}

resource "aws_security_group_rule" "ecs-allow-http" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks       = ["${var.cidr_prefix[terraform.workspace]}.0.0/16"]
  security_group_id = aws_security_group.ecs-sg.id
}

resource "aws_security_group_rule" "ecs-allow-ws" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3334
  to_port           = 3334
  cidr_blocks       = ["${var.cidr_prefix[terraform.workspace]}.0.0/16"]
  security_group_id = aws_security_group.ecs-sg.id
}

resource "aws_security_group_rule" "ecs-allow-self" {
  type              = "ingress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["${var.cidr_prefix[terraform.workspace]}.0.0/16"]
  security_group_id = aws_security_group.ecs-sg.id
}

resource "aws_security_group_rule" "ecs-allow-outbound" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs-sg.id
}
