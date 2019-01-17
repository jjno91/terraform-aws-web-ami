#################################################
# EC2
#################################################

#################################################
# S3
#################################################

#################################################
# ALB
#################################################

#################################################
# Route 53
#################################################

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
