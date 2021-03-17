data "archive_file" "alerts-lambda-archive" {
  type        = "zip"
  source_dir  = "alerts-lambda"
  output_path = "alerts-lambda.zip"
}

resource "aws_lambda_function" "alerts-lambda" {
  filename         = "alerts-lambda.zip"
  source_code_hash = data.archive_file.alerts-lambda-archive.output_base64sha256
  function_name    = "${terraform.workspace}-alerts"
  role             = aws_iam_role.lambda-role.arn
  handler          = "main.handler"
  runtime          = "python3.8"

  environment {
    variables = {
      TELEGRAM_CHANNEL_ID = var.telegram_channel_id
    }
  }
}

resource "aws_lambda_permission" "allow-sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alerts-lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts-topic.arn
}
