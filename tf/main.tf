terraform {
  required_version = "~> 1.0.10"

  required_providers {
    aws     = "~> 3.63"
    archive = "~> 2.2"
  }
}

provider "aws" {
  region                  = "ca-central-1"
  shared_credentials_file = "$HOME/.aws/credentials"
  profile                 = "serverless-rails-demo"
  skip_region_validation  = true
}

terraform {
  backend "s3" {
    bucket         = "serverless-rails-demo--tf-state"
    key            = "terraform.tfstate"
    region         = "ca-central-1"
    profile        = "serverless-rails-demo"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}

variable "application_name" { type = string }
variable "application_host" { type = string }
variable "maintenance_mode" { type = map(bool) }
variable "cidr_prefix" { type = map(string) }
variable "ssh_ips" { type = map(list(string)) }
variable "service_size" { type = map(map(map(number))) }
variable "service_count" { type = map(map(map(number))) }
variable "telegram_channel_id" { type = string }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" { state = "available" }

output "aws_region" { value = data.aws_region.current.name }

# Route 53 zone nameservers
output "name_servers" { value = aws_route53_zone.zone.name_servers }

# docker image repo
output "repo_url" { value = aws_ecr_repository.repo.repository_url }
output "repo_arn" { value = aws_ecr_repository.repo.arn }

# cache
output "redis_host" { value = aws_elasticache_cluster.redis.cache_nodes.0.address }

# database
output "database_host" { value = aws_rds_cluster.db.endpoint }
output "database_password" {
  sensitive = true
  value     = random_password.rds-password.result
}

# s3/cloudfront
output "uploads_bucket" { value = aws_s3_bucket.uploads-bucket.id }
output "client_assets_bucket" { value = aws_s3_bucket.client-assets-bucket.id }
output "client_assets_cloudfront" { value = aws_cloudfront_distribution.client-assets-cdn.domain_name }

# sns topic for alerts
output "alerts_sns" { value = aws_sns_topic.alerts-topic.arn }

# ecs cluster
output "cluster_id" { value = aws_ecs_cluster.cluster.name }

# service names
output "web_service" { value = aws_ecs_service.web-service.name }
output "worker_service" { value = aws_ecs_service.worker-service.name }
output "cable_service" { value = aws_ecs_service.cable-service.name }

# task definitions
output "web_task" { value = aws_ecs_task_definition.web-task.id }
output "worker_task" { value = aws_ecs_task_definition.worker-task.id }
output "cable_task" { value = aws_ecs_task_definition.cable-task.id }
output "migrate_task" { value = aws_ecs_task_definition.migrate-task.id }
output "job_task" { value = aws_ecs_task_definition.job-task.id }
output "shell_task" { value = aws_ecs_task_definition.shell-task.id }

# scheduled jobs
output "every_1_hour_rule" { value = aws_cloudwatch_event_rule.every-1-hour.name }

# for one-off tasks to use
output "public_subnets" { value = aws_subnet.public.*.id }
output "ecs_security_group" { value = aws_security_group.ecs-sg.id }
output "ssh_security_group" { value = aws_security_group.ssh-sg.id }
