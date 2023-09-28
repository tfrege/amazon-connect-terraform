resource "aws_sqs_queue" "queue" {
    name                        = format("%s_schedule_changes_sqs", var.name)
    delay_seconds               = var.delay
    visibility_timeout_seconds  = 60
    policy = "{\"Id\":\"__default_policy_ID\",\"Statement\":[{\"Action\":\"SQS:*\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"arn:aws:iam::797976833309:role/service-role/connect-sample-lambda-role-e69cxys8\",\"arn:aws:iam::797976833309:root\"]},\"Resource\":\"arn:aws:sqs:us-east-1:797976833309:spacenav_schedule_change\",\"Sid\":\"__owner_statement\"}],\"Version\":\"2012-10-17\"}"

   # tags = var.tags

}

