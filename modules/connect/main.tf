


resource "aws_iam_role" "connect_service_role" {
    name   = format("%s-connect-service-role", var.name) 
assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
    "Action": "sts:AssumeRole",
    "Principal": {
    "Service": "connect.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
}
]
}
EOF
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
      sid = "1"
      actions = ["iam:DeleteRole"]
      resources = ["arn:aws:iam::*:role/aws-service-role/connect.amazonaws.com/AWSServiceRoleForAmazonConnect_*"]
  }

  statement {
    actions = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
    ]

    resources = [
      "${var.s3_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
            "s3:GetBucketLocation",
            "s3:GetBucketAcl"
    ]

    resources = [
      var.s3_bucket_arn
    ]
  }

  statement {
    actions = [
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/connect/*:*"
    ]
  }

  statement {
    actions = [
          "lex:ListBots",
          "lex:ListBotAliases"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
          "cloudwatch:PutMetricData"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
                "connect:Get*",
                "connect:Describe*",
                "connect:List*",
                "ds:DescribeDirectories"
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"

      values = [
        "*arn:aws:connect:us-east-1:417359174056*"
      ]
    }
  }
}

resource "aws_iam_policy" "connect_service_policy" {
    name         = format("%s-connect-instance-policy", var.name) 
    path         = "/"
    description  = format("%s-connect-instance-policy", var.name) 
    policy = data.aws_iam_policy_document.policy_doc.json
}
 
resource "aws_iam_role_policy_attachment" "role_policy_1" {
    role        = aws_iam_role.connect_service_role.name
    policy_arn  = aws_iam_policy.connect_service_policy.arn
}

# instance
resource "aws_connect_instance" "instance"{
    identity_management_type            = "CONNECT_MANAGED"
    auto_resolve_best_voices_enabled    = true
    contact_flow_logs_enabled           = true
    contact_lens_enabled                = true
    directory_id                        = null
    early_media_enabled                 = true
    inbound_calls_enabled               = true
    instance_alias                      = format("%s-connect-instance", var.name) 
    multi_party_conference_enabled      = true
    outbound_calls_enabled              = true
    #service_role                        = aws_iam_role.connect_service_role.arn
    timeouts {
        create = "60m"
        delete = "2h"
    }
}




resource "aws_connect_instance_storage_config" "store_calls" {
  instance_id   = aws_connect_instance.instance.id
  depends_on = [ aws_connect_instance.instance ]
  resource_type = "CALL_RECORDINGS"

  storage_config {
    s3_config {
      bucket_name   = var.s3_bucket_id
      bucket_prefix = "callrecordings"      
    }

    storage_type = "S3"
  }
}


# phone number
resource "aws_connect_phone_number" "phone" {
  target_arn   = aws_connect_instance.instance.arn
  depends_on = [ aws_connect_instance.instance ]
  country_code = "US"
  type         = "TOLL_FREE"

  tags = {
    "hello" = "world"
  }
}

# hours of operation
resource "aws_connect_hours_of_operation" "hours"{
  instance_id = aws_connect_instance.instance.id
  depends_on = [ aws_connect_instance.instance ]
  name        = format("%s-hours-of-operation", var.name) 
  description = format("%s hours of operation", var.name)
  time_zone   = var.timezone

  config {
    day = "MONDAY"

    end_time {
      hours   = 23
      minutes = 8
    }

    start_time {
      hours   = 8
      minutes = 0
    }
  }
}

# queue
resource "aws_connect_queue" "main_queue"{
    instance_id                 = aws_connect_instance.instance.id
    name                        = format("%s-main-queue", var.name) 
    description                 = format("%s Main Queue", var.name) 
    hours_of_operation_id       = aws_connect_hours_of_operation.hours.hours_of_operation_id
    status                      = "ENABLED"
    depends_on                  = [ aws_connect_hours_of_operation.hours ]
}

resource "aws_connect_queue" "backup_queue"{
    instance_id                 = aws_connect_instance.instance.id
    name                        = format("%s-backup-queue", var.name) 
    description                 = format("%s Backup Queue", var.name) 
    hours_of_operation_id       = aws_connect_hours_of_operation.hours.hours_of_operation_id
    status                      = "ENABLED"
    depends_on                  = [ aws_connect_hours_of_operation.hours ]
}



# routing profile
resource "aws_connect_routing_profile" "main_routing_profile"{
    instance_id                 = aws_connect_instance.instance.id
    name                        = format("%s-main-routing-profile", var.name) 
    description                 = format("%s Main Routing Profile", var.name) 
    default_outbound_queue_id   = aws_connect_queue.backup_queue.queue_id

    media_concurrencies {
        channel     = "VOICE"
        concurrency = 1
    }

    queue_configs {
        channel  = "VOICE"
        delay    = 5
        priority = 1
        queue_id = aws_connect_queue.main_queue.queue_id
    }
}

resource "aws_connect_routing_profile" "backup_routing_profile"{
    instance_id                 = aws_connect_instance.instance.id
    name                        = format("%s-backup-routing-profile", var.name) 
    description                 = format("%s Backup Routing Profile", var.name) 
    default_outbound_queue_id   = aws_connect_queue.backup_queue.queue_id

    media_concurrencies {
        channel     = "VOICE"
        concurrency = 1
    }

    queue_configs {
        channel  = "VOICE"
        delay    = 5
        priority = 1
        queue_id = aws_connect_queue.backup_queue.queue_id
    }
}

data "aws_connect_security_profile" "admin_security_profile" {
  instance_id = aws_connect_instance.instance.id
  name        = "Admin"
}

data "aws_connect_security_profile" "agent_security_profile" {
  instance_id = aws_connect_instance.instance.id
  name        = "Agent"
}



resource "random_password" "password_admin" {
  length           = 10
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper = 1 
  min_lower = 1
  min_numeric = 1 
  min_special = 1
}

resource "aws_connect_user" "admin"{
  instance_id        = aws_connect_instance.instance.id
  name               = "Admin"
  password           = random_password.password_admin.result
  routing_profile_id = aws_connect_routing_profile.main_routing_profile.routing_profile_id

  security_profile_ids = [
    data.aws_connect_security_profile.admin_security_profile.security_profile_id
  ]

  identity_info {
    first_name = "SpaceNav"
    last_name  = "Admin"
    email = "tfrege@amazon.com"
  }

  phone_config {
    after_contact_work_time_limit   = 10
    phone_type                      = "DESK_PHONE"
    auto_accept                     = true
    desk_phone_number               = var.default_phone_number
  }
}


resource "random_password" "password_agent" {
  length           = 10
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper = 1 
  min_lower = 1
  min_numeric = 1 
  min_special = 1
}

resource "aws_connect_user" "agent"{
  instance_id        = aws_connect_instance.instance.id
  name               = "Agent"
  password           = random_password.password_agent.result
  routing_profile_id = aws_connect_routing_profile.main_routing_profile.routing_profile_id

  security_profile_ids = [
    data.aws_connect_security_profile.agent_security_profile.security_profile_id
  ]

  identity_info {
    first_name = "SpaceNav"
    last_name  = "Agent"
    email = "tfrege@amazon.com"
  }

  phone_config {
    after_contact_work_time_limit   = 10
    phone_type                      = "DESK_PHONE"
    auto_accept                     = true
    desk_phone_number               = var.default_phone_number
  }
}


resource "random_password" "password_backup" {
  length           = 10
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper = 1 
  min_lower = 1
  min_numeric = 1 
  min_special = 1
}

resource "aws_connect_user" "backup"{
  instance_id        = aws_connect_instance.instance.id
  name               = "Backup"
  password           = random_password.password_backup.result
  routing_profile_id = aws_connect_routing_profile.main_routing_profile.routing_profile_id

  security_profile_ids = [
    data.aws_connect_security_profile.agent_security_profile.security_profile_id
  ]

  identity_info {
    first_name = "SpaceNav"
    last_name  = "Backup"
    email = "tfrege@amazon.com"
  }

  phone_config {
    after_contact_work_time_limit   = 10
    phone_type                      = "DESK_PHONE"
    auto_accept                     = true
    desk_phone_number               = var.default_phone_number
  }
}


# flow
resource "aws_connect_contact_flow" "the_flow" {
  instance_id = aws_connect_instance.instance.id

  name        = format("%s-flow", var.name) 
  description = format("%s Flow", var.name) 
  type        = "CONTACT_FLOW"
  content = jsonencode({
    "Version":"2019-10-30",
    "StartAction":"record_call",
    "Actions":[
       {
          "Parameters":{
             "ThirdPartyPhoneNumber":var.default_phone_number,
             "ThirdPartyConnectionTimeLimitSeconds":"30",
             "ContinueFlowExecution":"True"
          },
          "Identifier":"transfer_to_phone",
          "Type":"TransferParticipantToThirdParty",
          "Transitions":{
             "NextAction":"disconnect_call",
             "Errors":[
                {
                   "NextAction":"disconnect_call",
                   "ErrorType":"CallFailed"
                },
                {
                   "NextAction":"disconnect_call",
                   "ErrorType":"ConnectionTimeLimitExceeded"
                },
                {
                   "NextAction":"disconnect_call",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             
          },
          "Identifier":"disconnect_call",
          "Type":"DisconnectParticipant",
          "Transitions":{
             
          }
       },
       {
          "Parameters":{
             "QueueId":aws_connect_queue.main_queue.arn
          },
          "Identifier":"update_contact_target_queue1",
          "Type":"UpdateContactTargetQueue",
          "Transitions":{
             "NextAction":"check_hours_queue1",
             "Errors":[
                {
                   "NextAction":"message_participant",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             
          },
          "Identifier":"transfer_contact_to_queue2",
          "Type":"TransferContactToQueue",
          "Transitions":{
             "NextAction":"message_participant",
             "Errors":[
                {
                   "NextAction":"transfer_to_phone",
                   "ErrorType":"QueueAtCapacity"
                },
                {
                   "NextAction":"message_participant",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             
          },
          "Identifier":"check_hours_queue1",
          "Type":"CheckHoursOfOperation",
          "Transitions":{
             "NextAction":"message_participant",
             "Conditions":[
                {
                   "NextAction":"transfer_contact_to_queue1",
                   "Condition":{
                      "Operator":"Equals",
                      "Operands":[
                         "True"
                      ]
                   }
                },
                {
                   "NextAction":"update_contact_queue2",
                   "Condition":{
                      "Operator":"Equals",
                      "Operands":[
                         "False"
                      ]
                   }
                }
             ],
             "Errors":[
                {
                   "NextAction":"message_participant",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             "Text":"We are sorry we are not able to take your call."
          },
          "Identifier":"message_participant",
          "Type":"MessageParticipant",
          "Transitions":{
             "NextAction":"disconnect_call",
             "Errors":[
                {
                   "NextAction":"disconnect_call",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             
          },
          "Identifier":"transfer_contact_to_queue1",
          "Type":"TransferContactToQueue",
          "Transitions":{
             "NextAction":"message_participant",
             "Errors":[
                {
                   "NextAction":"update_contact_queue2",
                   "ErrorType":"QueueAtCapacity"
                },
                {
                   "NextAction":"message_participant",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             "QueueId":aws_connect_queue.backup_queue.arn
          },
          "Identifier":"update_contact_queue2",
          "Type":"UpdateContactTargetQueue",
          "Transitions":{
             "NextAction":"transfer_contact_to_queue2",
             "Errors":[
                {
                   "NextAction":"message_participant",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             "Text":"Thank you for calling SpaceNav."
          },
          "Identifier":"message_caller_greeting",
          "Type":"MessageParticipant",
          "Transitions":{
             "NextAction":"update_contact_target_queue1",
             "Errors":[
                {
                   "NextAction":"message_participant",
                   "ErrorType":"NoMatchingError"
                }
             ]
          }
       },
       {
          "Parameters":{
             "RecordingBehavior":{
                "RecordedParticipants":[
                   "Agent",
                   "Customer"
                ]
             }
          },
          "Identifier":"record_call",
          "Type":"UpdateContactRecordingBehavior",
          "Transitions":{
             "NextAction":"message_caller_greeting"
          }
       }
    ]
 })
}

/*
resource "aws_connect_phone_number_contact_flow_association" "associate_phone_with_flow" {
    phone_number_id = aws_connect_phone_number.phone.id
    instance_id = aws_connect_instance.instance.id
    contact_flow_id = aws_contact_flow.the_flow.id
}*/