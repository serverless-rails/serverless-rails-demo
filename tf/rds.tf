resource "aws_rds_cluster" "db" {
  engine                 = "aurora-postgresql"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  cluster_identifier     = "${terraform.workspace}-db"
  database_name          = "app"
  availability_zones     = slice(data.aws_availability_zones.available.names, 0, 3)
  apply_immediately      = true
  engine_mode            = "serverless"
  vpc_security_group_ids = [aws_security_group.ecs-sg.id]
  skip_final_snapshot    = true

  master_username = "app"
  master_password = random_password.rds-password.result

  scaling_configuration {
    min_capacity = 2
    max_capacity = 16
  }
}

resource "random_password" "rds-password" {
  length  = 36
  special = false
}
