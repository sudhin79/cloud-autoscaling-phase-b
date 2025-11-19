resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.ec2_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(file("${path.module}/user-data-phaseb.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "app-instance"
      Project = "lift-and-shift"
    }
  }
}
