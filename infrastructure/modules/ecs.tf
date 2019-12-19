/*
  ECS cluster and ECR repository where to host Docker images
*/

resource "aws_ecs_cluster" "strava_feedme_ecs_cluster" {
  name = "${var.appname}-strava-feedme-ecs-cluster-${var.env}"
}

resource "aws_ecr_repository" "strava_feedme_ecr_repo" {
  name = "${var.appname}-strava-feedme-images-repository-${var.env}"
}

/*
  Cloudwatch logs group
*/

resource "aws_cloudwatch_log_group" "strava_feedme_logs" {
  name = "${var.appname}-ecs-strava-feedme-${var.env}"

  tags = {
    Project = "${var.appname}-${var.env}"
    Team    = "Personal_AG"
  }
}

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "strava_feedme_ecs_execution_role" {
  name = "${var.appname}-ecs_task_execution_role"

  assume_role_policy = <<EOF
{"Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "strava_feedme_ecs_execution_role_policy" {
  name = "${var.appname}-ecs_execution_role_policy"
  role = "${aws_iam_role.strava_feedme_ecs_execution_role.id}"

  policy = <<EOF
{"Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObjectVersion",
        "s3:GetBucketLogging",
        "s3:ReplicateTags",
        "s3:ListBucket",
        "s3:GetBucketPolicy",
        "s3:ReplicateObject",
        "s3:GetObjectAcl",
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:DeleteObjectTagging",
        "s3:PutObject",
        "s3:GetObject",
        "s3:PutBucketNotification",
        "s3:GetObjectTorrent",
        "s3:GetBucketLocation",
        "s3:GetObjectVersion"
      ],
      "Resource": ["${aws_s3_bucket.com-strava-feedme.arn}",
                   "${aws_s3_bucket.com-strava-feedme.arn}/*"]
    }
  ]
}
EOF
}
