data "aws_iam_policy_document" "ecs-assume-role-policy" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
        "events.amazonaws.com",
        "ec2.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

#
# LAMBDA (alerts)
#

resource "aws_iam_role" "lambda-role" {
  name               = "${terraform.workspace}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

#
# TASK EXECUTION ROLE
#

resource "aws_iam_role" "ecs-task-execution-role" {
  name               = "${terraform.workspace}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]
}

#
# EVENTS (jobs)
#

resource "aws_iam_role" "ecs-events-role" {
  name               = "${terraform.workspace}-ecs-events-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role-policy.json

  inline_policy {
    name = "run-task-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "iam:PassRole"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "ecs:RunTask",
          Effect   = "Allow"
          Resource = replace(aws_ecs_task_definition.job-task.arn, "/:\\d+$/", ":*")
        }
      ]
    })
  }
}

#
# AUTOSCALING
#

resource "aws_iam_role" "ecs-autoscale-role" {
  name                = "${terraform.workspace}-ecs-autoscale-role"
  assume_role_policy  = data.aws_iam_policy_document.ecs-assume-role-policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"]
}
