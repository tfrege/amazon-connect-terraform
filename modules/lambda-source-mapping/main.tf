resource "aws_lambda_event_source_mapping" "trigger_lambda" {
  batch_size        = 1
  event_source_arn = var.sqs_arn
  function_name    = var.lambda_arn
  enabled          = true
}

