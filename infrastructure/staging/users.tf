resource "aws_iam_user" "rw-com-strava-feedme-user-ag" {
  name          = "rw-${var.appname}-user-ag"
  path          = "/misc_users/"
  force_destroy = true
}

resource "aws_iam_user_policy" "rw-com-strava-feedme-policy-ag" {
  name = "rw-${var.appname}-policy-ag"
  user = aws_iam_user.rw-com-strava-feedme-user-ag.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": [
        "${module.infrastructure.com_strava_feedme_bucket_arn}",
        "${module.infrastructure.com_strava_feedme_bucket_arn}/*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_access_key" "rw-com-strava-feedme-access_key" {
  user = aws_iam_user.rw-com-strava-feedme-user-ag.name
}

output "rw_com-strava-feedme-access_key_id" {
  value = aws_iam_access_key.rw-com-strava-feedme-access_key.id
}

output "rw_com-strava-feedme-secret_access_key" {
  value = aws_iam_access_key.rw-com-strava-feedme-access_key.secret
}

