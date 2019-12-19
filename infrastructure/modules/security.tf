# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "ecs-app-security-group" {
  name        = "ecs-app-security-group"
  description = "controll acess to the container app"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}