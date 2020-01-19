resource "aws_key_pair" "bastion_key" {
  key_name   = "strava_bastion_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCjD0F94XH5hVaWfF8KU2OYsgzi7VHMGpbry40rmNSITxaLa4FaqC6tiaOBGvLbF8weUq4MGWrj1RJWy/AIEJdo0LLTtwnaWKYSF30qrJNIDAlaZMrw8gNlOp6ULs3i3Cyw4SmnWFIMC2guWWV2dO7Dpjq6Lt6deskZ2I6ZBp0R7pOqzu4DJ6c8wRgnJKK6eJs96CAwErRPktEWuuN9fXThqN69zRp0BpzJa722sRNC79DtppG1b1ZY4l0fL6p/Itds6YoChVQ/xK4mag7UqLReq10RFcbj2U0W/gSSTif9Ao9L/Si8z1nqtIPnRlyNQHMZwQtiycV/SjFF1OeHu+CmXEk+TAEhQ8/a5Es/LV/1CNIhBCHYqSF9OXsJX0GfOQ9NKqWzjxrNuVvKRvrpHFYSfeG8AlDtatN8kDodDti5J9rVFBfRVo1VqjXNelDlHQhe6RurcKeC583la3Nmr9WQPBzLPTlBR/9tbsg5kAv6nUBQdKq+duCy3xwZ5hwjMSBkdcGt0vigJBNh23BoJMysj25TuycGgVWnB01XcFjCD7stvNyiK2ol9p1FYSVv9nFg7jAWBLcalwBo2hOYbvQBZs3Rjo8ki8qjgGYU54Q0uznITbduZ4etSL5T5lodvdOWXVydggBSb6x7K05trsk7DqpHlE7J2M5bMlxC8BNLCw== alessio.gastaldo@gmail.com"
}


resource "aws_security_group" "bastion_security_group" {
  name = "${var.environment}-bastion-sg"
  description = "${var.environment} Bastion Security Group"
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.environment}-bastion-sg"
    Environment =  "${var.environment}"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${var.home_ip_address}"]
  }

   egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  // allows traffic from the SG itself
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      self = true
  }
}

resource "aws_instance" "bastion" {
  ami                         = "ami-0713f98de93617bb4"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.bastion_key.key_name}"
  associate_public_ip_address = true
  subnet_id                   = "${aws_subnet.public_subnet.0.id}"
  security_groups             = ["${aws_security_group.bastion_security_group.id}"]

}
