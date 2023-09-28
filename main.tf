data "aws_caller_identity" "current" {}

module "CreateConnectS3Bucket" {
  source                    = "./modules/s3"
  name                      = var.name
  tags                      = local.tags
}

module "CreateConnect" {
  source                    = "./modules/connect"
  name                      = var.name
  timezone                  = var.timezone
  s3_bucket_arn             = module.CreateConnectS3Bucket.bucket_arn
  s3_bucket_id              = module.CreateConnectS3Bucket.bucket_id
  tags                      = local.tags
}

module "CreateSecretAdminAccount" {
  source                    = "./modules/secrets-manager"
  username                  = "Admin"
  password                  = module.CreateConnect.admin_password
  secret_name               = format("%s/connect/users/%s", var.name, "Admin")
  connect_url               = format("https://%s-connect-instance.my.connect.aws", var.name)
  tags                      = local.tags
}

module "CreateSecretAgentAccount" {
  source                    = "./modules/secrets-manager"
  username                  = "Agent"
  password                  = module.CreateConnect.agent_password
  secret_name               = format("%s/connect/users/%s", var.name, "Agent")
  connect_url               = format("https://%s-connect-instance.my.connect.aws", var.name)
  tags                      = local.tags
}

module "CreateSecretBackupAccount" {
  source                    = "./modules/secrets-manager"
  username                  = "Backup"
  password                  = module.CreateConnect.backup_password
  secret_name               = format("%s/connect/users/%s", var.name, "Backup")
  connect_url               = format("https://%s-connect-instance.my.connect.aws", var.name)
  tags                      = local.tags
}



