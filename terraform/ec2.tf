resource "aws_key_pair" "aduca" {
  key_name   = "aduca_key"
  public_key = file("") # Replace with the path to your SSH public key
}

resource "aws_security_group" "ssh_access" {
  name_prefix = "ssh_access"
  vpc_id = aws_vpc.aduca.id

  # This rule is needed to be able to ssh into the instance
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [""] # Replace with your egress IP `curl ifconfig.me`
  }
}

resource "aws_network_interface" "aduca" {
  subnet_id       = aws_subnet.aduca.id
  security_groups = [aws_security_group.ssh_access.id]
}

resource "aws_instance" "aduca" {
  ami           = "ami-0720a3ca2735bf2fa"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.aduca.key_name
  user_data     = file("userdata.sh")

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.aduca.id
  }

  tags = {
    Name = "aduca-instance"
  }
}

resource "aws_eip" "ec2" {
  instance = aws_instance.aduca.id
}


output "public_ip" {
  value = aws_instance.aduca.public_ip
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-tagging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for EC2 tagging
resource "aws_iam_policy" "ec2_tagging_policy" {
  name        = "EC2TaggingPolicy"
  description = "Allows EC2 instances to tag other EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ]
      Resource = "*"
    }]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_tagging_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_tagging_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# Launch template for EC2 instances
resource "aws_launch_template" "template" {
  name          = "aduca-launch-template"
  image_id      = "ami-0720a3ca2735bf2fa"  # Replace with your AMI ID
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "aduca-instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "foo_asg" {
  name                = "aduca-asg"
  desired_capacity    = 2
  min_size           = 1
  max_size           = 3
  vpc_zone_identifier = [aws_subnet.aduca.id]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "aduca-asg-instance"
    propagate_at_launch = true
  }
}