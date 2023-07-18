provider "aws" {
  region = "eu-west-2"
  access_key = "AKIAQS5TFTFOXXUOPHOQ"
  secret_key = "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"
}

module "new_deployment" {
  source = "../modules/web_db_service"
  region = "eu-west-2"
  aws_vpc-website-vpc = "10.0.0.0/16"
  tenancy = "default"
  pub_sub_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  priv_app_sub_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
  instance_type = "t2.micro"
}