output "com_strava_feedme_bucket_arn" {
  value = "${aws_s3_bucket.com-strava-feedme.arn}"
}

output "com_strava_feedme_ecr_url" {
  value = "${aws_ecr_repository.strava_feedme_ecr_repo.repository_url}"
}