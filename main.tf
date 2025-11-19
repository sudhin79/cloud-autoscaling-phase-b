terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -----------------------
# Random suffix for uniqueness
# -----------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------
# S3 Bucket for Logs
# -----------------------
resource "aws_s3_bucket" "log_bucket" {
  bucket = "sudhin-app-logs-${random_id.suffix.hex}"

  tags = {
    Name = "app-log-bucket"
  }
}

# -----------------------
# IAM Role & Policy
# -----------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "ec2_s3_policy-${random_id.suffix.hex}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:GetObject", "s3:ListBucket"],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::sudhin-app-jar-bucket",
          "arn:aws:s3:::sudhin-app-jar-bucket/*"
        ]
      },
      {
        Action = ["s3:PutObject"],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.log_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.log_bucket.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2_role.name
}

# -----------------------
# Security Group
# -----------------------
resource "aws_security_group" "app_sg" {
  name        = "app-sg-${random_id.suffix.hex}"
  description = "Allow SSH, HTTP, and ALB traffic"

  ingress = [
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "HTTP"
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "HTTP from ALB"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = "Allow all outbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]


  tags = {
    Name = "app-sg"
  }
}

# -----------------------
# EC2 Instances
# -----------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-17-amazon-corretto-headless awscli
              mkdir -p /home/ec2-user/app
              aws s3 cp s3://sudhin-app-jar-bucket/hellomvc-0.0.1-SNAPSHOT.jar /home/ec2-user/app/
              nohup java -jar /home/ec2-user/app/hellomvc-0.0.1-SNAPSHOT.jar --server.port=8080 > /home/ec2-user/app/app.log 2>&1 &
              EOF

  tags = {
    Name = "app-instance-${count.index + 1}"
  }
}

# -----------------------
# Load Balancer (ALB)
# -----------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "app_alb" {
  name               = "alb-${random_id.suffix.hex}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "app_tg" {
  name     = "tg-${random_id.suffix.hex}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = 3
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = 8080
}

# -----------------------
# Outputs
# -----------------------
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "ec2_public_ips" {
  value = aws_instance.app[*].public_ip
}

output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}

