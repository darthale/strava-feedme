resource "aws_s3_bucket" "com-strava-feedme" {
  bucket = "${var.bucket_name}"
  acl    = "private"
  region = "${var.region}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Project = "${var.appname}-${var.env}"
    Team    = "Personal_AG"
  }
}
