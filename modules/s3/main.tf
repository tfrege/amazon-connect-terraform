resource "aws_s3_bucket" "bucket" {
    bucket = format("%s-connect-bucket", var.name)
    force_destroy = true

}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
     # kms_master_key_id = var.kms_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "my_s3_bucket_lifecycle_config" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    id     = "dev_lifecycle_60_days"
    status = "Enabled"


    transition {
      storage_class = "GLACIER"
      days = 60
    }
    
  }
}