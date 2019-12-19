/*
  ECS cluster and ECR repository where to host Docker images
*/

resource "aws_ecs_cluster" "strava_feedme_ecs_cluster" {
  name = "${var.appname}-ecs-cluster-${var.env}"
}

resource "aws_ecr_repository" "strava_feedme_ecr_repo" {
  name = "${var.appname}-images-repository-${var.env}"
}

/*
  ECR deploy


resource "null_resource" "kamino_ecr_deploy" {
  # this a temporary deploy, just to get things up and running

  triggers {
    new_deploy = "$(timestamp())"
  }

  provisioner "local-exec" {
    command = <<EOT
      $(aws ecr get-login --no-include-email --region ${var.region}) \
      && docker build -t ${var.image_name} ../container/. \
      && docker tag ${var.image_name}:${var.image_tag} ${aws_ecr_repository.kamino_ecr_repo.repository_url} \
      && docker push ${aws_ecr_repository.kamino_ecr_repo.repository_url}
  EOT
  }

  depends_on = ["aws_ecr_repository.kamino_ecr_repo"]
}*/

/*
  Cloudwatch logs group
*/

resource "aws_cloudwatch_log_group" "strava_feedme_logs" {
  name = "${var.appname}-ecs-build-${var.env}"

  tags {
    Project = "${var.appname}-${var.env}"
    Team    = "Personal_AG"
  }
}

/*
  ECS task definitions
*/

data "template_file" "superset_task" {
  template = "${file("${path.module}/tasks/task_definition.json")}"

  vars {
    task_name              = "${var.appname}-${var.superset_task_name}"
    region                 = "${var.region}"
    logs_group             = "${aws_cloudwatch_log_group.build_logs.name}"
    image                  = "${aws_ecr_repository.kamino_ecr_repo.repository_url}"
    score_sqs_url          = "${aws_sqs_queue.score_queue.id}"
    build_sqs_url          = "${aws_sqs_queue.build_queue.id}"
    score_sqs_dlq_url      = "${aws_sqs_queue.dlq_score_queue.id}"
    build_sqs_dlq_url      = "${aws_sqs_queue.dlq_build_queue.id}"
    dynamo_tracking_table  = "${aws_dynamodb_table.tracking_table.id}"
    athena_ids_location    = "${aws_s3_bucket.com-liveramp-eu-onboarding-kamino.id}/athena_ids/"
    athena_ids_table       = "${aws_athena_database.user_base_db.name}.id"
    athena_results         = "${aws_s3_bucket.com-liveramp-eu-internal-kamino.id}/athena_results/"
    athena_database        = "${aws_athena_database.user_base_db.name}"
    cloudwatch_idle_metric = "${var.appname}-${var.superset_task_name}-idle-metric"
    cloudwatch_namespace   = "StravaFeedMe/ECS"
    run_type               = "build"
  }

  depends_on = ["null_resource.kamino_ecr_deploy"]
}

resource "aws_ecs_task_definition" "build_task" {
  family                   = "${var.appname}-build-task-${var.env}"
  container_definitions    = "${data.template_file.build_task.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.build_task_cpu}"
  memory                   = "${var.build_task_memory}"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.ecs_execution_role.arn}"

  depends_on = ["data.template_file.build_task"]
}


/*
* IAM service role
*/

/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "ecs_execution_role" {
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

# TODO: lock down actions for Glue and Athena
resource "aws_iam_role_policy" "ecs_execution_role_policy" {
  name = "${var.appname}-ecs_execution_role_policy"
  role = "${aws_iam_role.ecs_execution_role.id}"

  policy = <<EOF
{"Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Action": [
         "sqs:SendMessage",
         "sqs:GetQueueUrl",
         "sqs:DeleteMessage",
         "sqs:ReceiveMessage"
      ],
      "Effect": "Allow",
      "Resource": ["${aws_sqs_queue.build_queue.arn}",
                   "${aws_sqs_queue.score_queue.arn}",
                   "${aws_sqs_queue.dlq_build_queue.arn}",
                   "${aws_sqs_queue.dlq_score_queue.arn}"]
    },
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
      "Resource": ["${aws_s3_bucket.com-liveramp-eu-onboarding-kamino.arn}",
                   "${aws_s3_bucket.com-liveramp-eu-onboarding-kamino.arn}/*",
                   "${aws_s3_bucket.com-liveramp-eu-internal-kamino.arn}",
                   "${aws_s3_bucket.com-liveramp-eu-internal-kamino.arn}/*"]
    },
    {
      "Action": [
        "dynamodb:UpdateItem",
        "dynamodb:PutItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:ListTables",
        "dynamodb:Query"
      ],
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.tracking_table.arn}"
    },
    {
      "Action": [
        "athena:StartQueryExecution",
        "athena:GetQueryResultsStream",
        "athena:GetQueryResults",
        "athena:GetQueryExecutions",
        "athena:CancelQueryExecution",
        "athena:StopQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetTables",
        "athena:GetTable",
        "athena:RunQuery"
      ],
      "Effect": "Allow",
      "Resource": ["*"]
    },
  {
      "Action": [
        "glue:GetTable",
        "glue:GetPartition",
        "glue:GetPlan",
        "glue:BatchCreatePartition",
        "glue:GetPartitions",
        "glue:BatchDeletePartition",
        "glue:UpdateTable",
        "glue:CreatePartition",
        "glue:UpdatePartition",
        "glue:UpdateDatabase",
        "glue:CreateTable",
        "glue:GetTables",
        "glue:BatchGetPartition",
        "glue:GetDatabases",
        "glue:GetTable",
        "glue:GetDatabase",
        "glue:GetPartition",
        "glue:CreateDatabase",
        "glue:GetPlan"
      ],
      "Effect": "Allow",
      "Resource": ["*"]
    },
    {
         "Effect":"Allow",
         "Action":[
            "application-autoscaling:*",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:PutMetricData"
         ],
         "Resource":[
            "*"
         ]
      }
  ]
}
EOF
}

/*
  ECS services
*/

resource "aws_ecs_service" "superset_service" {
  name            = "${var.appname}-superset-service-${var.env}"
  task_definition = "${aws_ecs_task_definition.superset_task.family}:${max("${aws_ecs_task_definition.superset_task.revision}", "${aws_ecs_task_definition.superset_task.revision}")}"
  desired_count   = 1
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.strava_feedme_ecs_cluster.id}"
  depends_on      = ["aws_ecs_task_definition.superset_task"]

  network_configuration {
    security_groups = ["${aws_security_group.ecs_service.id}"]
    subnets         = ["${module.shared.private_subnet_ids}"]
  }
}
