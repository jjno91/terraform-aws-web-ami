variable "env" {
  description = "(optional) Unique name of your Terraform environment to be used for naming and tagging resources"
  default     = "default"
}

variable "tags" {
  description = "(optional) Additional tags to be applied to all resources"
  default     = {}
}

variable "vpc_id" {
  description = "(required) ID of the VPC to which your AMI will be deployed"
  default     = ""
}

variable "instance_type" {
  description = "(optional) EC2 instance type"
  default     = "m5.large"
}

variable "ami_id" {
  description = "(required) AMI that will be launched"
  default     = ""
}

variable "port" {
  description = "(optional) Port of the EC2 instance to which the ALB will forward"
  default     = "8080"
}

variable "protocol" {
  description = "(optional) Protocol running on the port to which the ALB will forward"
  default     = "HTTP"
}

variable "acm_certificate_arn" {
  description = "(required) Certificate that will be loaded to the ALB listener for HTTPS encryption"
  default     = ""
}

variable "route53_zone_id" {
  description = "(required) Route 53 zone that that will register your DNS name"
  default     = ""
}

variable "dns_name" {
  description = "(required) DNS name that will forward to your ALB"
  default     = ""
}

variable "alb_subnet_ids" {
  description = "(required) Subnet(s) to which the ALB will be deployed"
  default     = []
}

variable "ec2_subnet_id" {
  description = "(required) Subnet(s) to which the EC2 instance will be deployed"
  default     = ""
}

variable "volume_size" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/instance.html#volume_size"
  default     = "50"
}

variable "delete_volume" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/instance.html#delete_on_termination"
  default     = "false"
}
