#################################################
# EC2
#################################################

resource "aws_instance" "this" {
  ami                     = "${var.ami_id}"
  instance_type           = "${var.instance_type}"
  vpc_security_group_ids  = ["${aws_security_group.ec2.id}"]
  subnet_id               = "${var.ec2_subnet_id}"
  ebs_optimized           = "true"
  tags                    = "${merge(map("Name", "${var.env}"), var.tags)}"
  volume_tags             = "${merge(map("Name", "${var.env}"), var.tags)}"
  disable_api_termination = "${var.data_protection}"

  root_block_device {
    volume_size           = "${var.volume_size}"
    delete_on_termination = !${var.data_protection}
  }
}

#################################################
# S3
#################################################

data "aws_elb_service_account" "this" {}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.env}-logs"
  acl           = "log-delivery-write"
  force_destroy = "true"
  tags          = "${var.tags}"

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.env}-logs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.this.arn}"
        ]
      }
    }
  ]
}
POLICY

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#################################################
# ALB
#################################################

resource "aws_lb" "this" {
  name               = "${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb.id}"]
  subnets            = ["${var.alb_subnet_ids}"]
  tags               = "${var.tags}"

  access_logs {
    bucket  = "${aws_s3_bucket.this.bucket}"
    prefix  = "alb"
    enabled = true
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.env}"
  port        = "${var.port}"
  protocol    = "${var.protocol}"
  vpc_id      = "${var.vpc_id}"
  target_type = "instance"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = "${aws_lb_target_group.this.arn}"
  target_id        = "${aws_instance.this.id}"
  port             = "${var.port}"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.acm_certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.this.id}"
    type             = "forward"
  }
}

#################################################
# Route 53
#################################################

resource "aws_route53_record" "this" {
  name    = "${var.dns_name}"
  type    = "A"
  zone_id = "${var.route53_zone_id}"

  alias {
    name                   = "${aws_lb.this.dns_name}"
    zone_id                = "${aws_lb.this.zone_id}"
    evaluate_target_health = false
  }
}

#################################################
# Security Groups
#################################################

resource "aws_security_group" "ec2" {
  name_prefix = "${var.env}-ec2-"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(map("Name", "${var.env}-ec2"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.env}-alb-"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(map("Name", "${var.env}-alb"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}

#################################################
# Ingress
#################################################

resource "aws_security_group_rule" "ec2_ingress_ec2" {
  description              = "Self ingress"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.ec2.id}"
  source_security_group_id = "${aws_security_group.ec2.id}"
}

resource "aws_security_group_rule" "ec2_ingress_alb" {
  description              = "ALB ingress"
  type                     = "ingress"
  from_port                = "${var.port}"
  to_port                  = "${var.port}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ec2.id}"
  source_security_group_id = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb_ingress_http" {
  description       = "HTTP ingress"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  description       = "HTTPS ingress"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

#################################################
# Egress
#################################################

resource "aws_security_group_rule" "ec2_egress_all" {
  description       = "Full egress"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.ec2.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress_ec2" {
  description              = "EC2 egress"
  type                     = "egress"
  from_port                = "${var.port}"
  to_port                  = "${var.port}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.alb.id}"
  source_security_group_id = "${aws_security_group.ec2.id}"
}
