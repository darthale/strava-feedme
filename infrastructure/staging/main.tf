terraform {
  backend s3 {
    bucket = "${var.state_bucket}"
    key    = "${var.state_file}"
    region = "${var.region}"
  }
}


provider "aws" {
  region = "${var.region}"
}


module "infrastructure" {
  source = "../modules"

  region = "${var.region}"
  env = "${var.env}"
  state_bucket = "${var.state_bucket}"
  state_file = "${var.state_file}"

  bucket_name = "${var.bucket_name}"

  appname = "${var.appname}"
}
