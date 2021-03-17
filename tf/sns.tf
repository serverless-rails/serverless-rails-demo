resource "aws_sns_topic" "alerts-topic" {
  name = "${terraform.workspace}-alerts"
}

resource "aws_sns_topic_subscription" "alerts-topic-subscription" {
  topic_arn = aws_sns_topic.alerts-topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alerts-lambda.arn
}
