terraform {
  backend "s3" {
    bucket = "${var.state_bucket}"
    key    = "${var.state_file}"
    region = "${var.region}"
  }
}

provider "aws" {
  region = var.region
}

module "infrastructure" {
  source = "../modules"

  region       = var.region
  environment  = var.environment
  state_bucket = var.state_bucket
  state_file   = var.state_file

  bucket_name = var.bucket_name

  appname = var.appname

  image_name           = var.image_name
  image_tag            = var.image_tag

  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones   = var.availability_zones
  vpc_cidr             = var.vpc_cidr
  http_inbound_eni_ip  = var.http_inbound_eni_ip
  home_ip_address = var.home_ip_address

  allocated_storage = var.allocated_storage
  instance_class = var.instance_class

  database_name = var.database_name
  database_username = var.database_username
  database_password = var.database_password
}

