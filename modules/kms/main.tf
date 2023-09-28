data "aws_caller_identity" "current" {}

resource "aws_kms_key" "a" {
    customer_master_key_spec = "SYMMETRIC_DEFAULT"
    enable_key_rotation = true
    is_enabled = true
    key_usage = "ENCRYPT_DECRYPT"
    description = format("%s-kms", var.name) 
    deletion_window_in_days = 10
}

data "aws_iam_policy_document" "policy_doc" {
  statement {
    sid = "1"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      "${aws_kms_key.a.arn}"
    ]



    principals {
      type        = "AWS"
      identifiers = ["*"] #"arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_kms_key_policy" "kms_policy" {
  key_id = aws_kms_key.a.id
  policy = data.aws_iam_policy_document.policy_doc.json
}

resource "aws_kms_alias" "a" {
  name          = format("alias/%s-kms", var.name) 
  target_key_id = aws_kms_key.a.key_id
}

