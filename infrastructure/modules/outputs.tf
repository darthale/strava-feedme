output "com_strava_feedme_bucket_arn" {
  value = "${aws_s3_bucket.com-strava-feedme.arn}"
}

/*output "com_strava_feedme_ecr_url" {
  value = "${aws_ecr_repository.strava_feedme_ecr_repo.repository_url}"
}*/

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnets_id" {
  value = ["${aws_subnet.public_subnet.*.id}"]
}

output "private_subnets_id" {
  value = ["${aws_subnet.private_subnet.*.id}"]
}

output "default_sg_id" {
  value = "${aws_security_group.default.id}"
}

output "security_groups_ids" {
  value = ["${aws_security_group.default.id}"]
}

output "rds_address" {
  value = "${aws_db_instance.rds.address}"
}

output "db_access_sg_id" {
  value = "${aws_security_group.db_access_sg.id}"
}