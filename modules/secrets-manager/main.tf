
resource "aws_secretsmanager_secret" "new_secret_object" {
  name                    = var.secret_name
  description             = format("Keys info for the user %s", var.username)
  recovery_window_in_days = 0
 
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "secret-policy",
    "Statement": [
        {
            "Sid": "AllowUseOfTheKey",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "*",
            "Condition": { "ForAnyValue:StringLike": { "secretsmanager:SecretId": "*${var.secret_name}*" } }
        }
    ]
}
EOF
}

resource "aws_secretsmanager_secret_version" "values" {
  secret_id     = aws_secretsmanager_secret.new_secret_object.id
  secret_string = <<EOF
    {
      "Username"       : "${var.username}",
      "Password"     : "${var.password}",
      "URL"     : "${var.connect_url}"
    }
EOF
}