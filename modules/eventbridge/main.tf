
resource "aws_iam_role" "role" {
    name   = format("%s-event-bridge-role", var.name) 
assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
    "Action": "sts:AssumeRole",
    "Principal": {
    "Service": "scheduler.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
}
]
}
EOF
}

resource "aws_iam_policy" "eventbridge_policy" {
    name         = format("%s-event-bridge-policy", var.name) 
    path         = "/"
    description  = format("Policy for Event Bridge %s", var.name) 
policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
    "Action": [
    "lambda:InvokeFunction"
    ],
    "Resource": "${var.lambda_target}",
    "Effect": "Allow"
}
]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role        = aws_iam_role.role.name
    policy_arn  = aws_iam_policy.eventbridge_policy.arn
}

resource "aws_scheduler_schedule" "event" {
    name = format("%s-event-bridge-schedule", var.name) 
    schedule_expression = "cron(45 * * * ? *)"
    schedule_expression_timezone = var.timezone
    state = "ENABLED"

    target {
        arn = var.lambda_target
        role_arn = aws_iam_role.role.arn
      
    }

    flexible_time_window {
        mode = "OFF"
    }
}

