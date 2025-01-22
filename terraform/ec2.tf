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
  ami           = "" # Replace with the AMI ID
  instance_type = "m5.large"
  key_name      = aws_key_pair.aduca.key_name
  user_data     = file("userdata.sh")

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