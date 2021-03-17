resource "aws_elasticache_subnet_group" "default" {
  name       = "${terraform.workspace}-cache-subnet-group"
  subnet_ids = aws_subnet.public.*.id
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${terraform.workspace}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  apply_immediately    = true
  subnet_group_name    = aws_elasticache_subnet_group.default.name
  security_group_ids   = [aws_security_group.ecs-sg.id]
  tags = {
    Name = "${terraform.workspace}-redis"
  }
}
