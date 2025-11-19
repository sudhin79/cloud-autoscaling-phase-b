variable "ami_id" {
  type        = string
  description = "AMI ID for EC2"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_profile_name" {
  type        = string
  description = "IAM Instance Profile Name"
}

variable "security_group_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnets for ASG"
}
