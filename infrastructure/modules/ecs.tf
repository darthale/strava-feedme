/*
  ECS cluster and ECR repository where to host Docker images
*/

resource "aws_ecs_cluster" "strava_feedme_ecs_cluster" {
  name = "strava-feedme-ecs-cluster-${var.environment}"
}

resource "aws_ecr_repository" "strava_feedme_ecr_repo" {
  name = "strava-feedme-images-repository-${var.environment}"
}

/*
  Cloudwatch logs group
*/
resource "aws_cloudwatch_log_group" "strava_feedme_logs" {
  name = "strava-feedme-ecs-logs-${var.environment}"

  tags = {
    Project = "${var.appname}-${var.environment}"
    Team    = "Personal_AG"
  }
}


/*
  ECR deploy
resource "null_resource" "stravafeedme_ecr_deploy" {
  # this a temporary deploy, just to get things up and running

  triggers = {
    new_deploy = "$(timestamp())"
  }

  provisioner "local-exec" {
    command = <<EOT
      $(aws ecr get-login --no-include-email --region ${var.region}) \
      && docker pull metabase/metabase \
      && docker tag  metabase/metabase:${var.image_tag} ${aws_ecr_repository.strava_feedme_ecr_repo.repository_url} \
      && docker push ${aws_ecr_repository.strava_feedme_ecr_repo.repository_url}
  EOT
  }

  depends_on = ["aws_ecr_repository.strava_feedme_ecr_repo"]
}
*/

/*====
ECS task definitions
======*/

/* the task definition for the web service */
data "template_file" "metabase_task" {
  template = "${file("${path.module}/tasks/metabase_task_definition.json")}"

  vars = {
    image           = "${aws_ecr_repository.strava_feedme_ecr_repo.repository_url}"
    # secret_key_base = "${var.secret_key_base}"
    database_type   = "postgres"
    database_name   = "${var.database_name}"
    database_port   = 5432
    database_username = "${var.database_username}"
    database_password = "${var.database_password}"
    database_host   = "${aws_db_instance.rds.address}"
    log_group       = "${aws_cloudwatch_log_group.strava_feedme_logs.name}"
  }
}

resource "aws_ecs_task_definition" "metabase" {
  family                   = "${var.environment}_metabase"
  container_definitions    = "${data.template_file.metabase_task.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = "${aws_iam_role.strava_feedme_ecs_execution_role.arn}"
  task_role_arn            = "${aws_iam_role.strava_feedme_ecs_execution_role.arn}"
}


/*====
App Load Balancer
======*/
resource "random_id" "target_group_sufix" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name     = "${var.environment}-alb-target-group-${random_id.target_group_sufix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.vpc.id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

/* security group for ALB */
resource "aws_security_group" "web_inbound_sg" {
  name        = "${var.environment}-web-inbound-sg"
  description = "Allow HTTP from Anywhere into ALB"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${var.http_inbound_eni_ip}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${var.home_ip_address}"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-inbound-sg"
  }
}

resource "aws_alb" "alb_strava_feedme" {
  name            = "${var.environment}-alb-stravafeedme"
  subnets         = ["${aws_subnet.public_subnet.0.id}", "${aws_subnet.public_subnet.1.id}"]
  security_groups = ["${aws_security_group.web_inbound_sg.id}", "${aws_security_group.default.id}", "${aws_security_group.db_access_sg.id}"]

  tags = {
    Project = "${var.appname}-${var.environment}"
    Team    = "Personal_AG"
  }
}

resource "aws_alb_listener" "listener_strava_feedme" {
  load_balancer_arn = "${aws_alb.alb_strava_feedme.arn}"
  port              = "80"
  protocol          = "HTTP"
  depends_on        = ["aws_alb_target_group.alb_target_group"]

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    type             = "forward"
  }
}

/* Needed for the ALB*/
resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
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

/* ecs service scheduler role */
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  role   = "${aws_iam_role.ecs_role.id}"
  policy = <<EOF
{"Version": "2012-10-17",
  "Statement": [
  {
      "Effect": "Allow",
      "Action": [
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


/* role that the Amazon ECS container agent and the Docker daemon can assume */
resource "aws_iam_role" "strava_feedme_ecs_execution_role" {
  name = "strava-feedme-ecs_task_execution_role"

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


/*====
ECS service
======*/

/* Security Group for ECS */
resource "aws_security_group" "ecs_service" {
  vpc_id      = "${aws_vpc.vpc.id}"
  name        = "${var.environment}-ecs-service-sg"
  description = "Allow egress from container"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ecs-service-sg"
    Environment = "${var.environment}"
  }
}

/* Simply specify the family to find the latest ACTIVE revision in that family */
data "aws_ecs_task_definition" "metabase" {
  task_definition = "${aws_ecs_task_definition.metabase.family}"

    depends_on = ["data.template_file.metabase_task"]

}

resource "aws_ecs_service" "metabase" {
  name            = "${var.environment}-web"
  task_definition = "${aws_ecs_task_definition.metabase.family}:${max("${aws_ecs_task_definition.metabase.revision}", "${data.aws_ecs_task_definition.metabase.revision}")}"
  desired_count   = 2
  launch_type     = "FARGATE"
  cluster         =  "${aws_ecs_cluster.strava_feedme_ecs_cluster.id}"

  network_configuration {
    security_groups = [ "${aws_security_group.default.id}", "${aws_security_group.db_access_sg.id}", "${aws_security_group.ecs_service.id}"]
    subnets         = ["${aws_subnet.private_subnet.0.id}", "${aws_subnet.private_subnet.1.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    container_name   = "metabase"
    container_port   = "3000"
  }

  depends_on = ["aws_alb_target_group.alb_target_group", "aws_iam_role_policy.ecs_service_role_policy", "aws_ecs_task_definition.metabase"]
}

