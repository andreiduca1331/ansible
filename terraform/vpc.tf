resource "aws_vpc" "aduca" {
  cidr_block = "10.0.0.0/16" # Replace with a CIDR block that is not used inside the AWS account
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.aduca.id

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "aduca" {
  vpc_id = aws_vpc.aduca.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
}


resource "aws_route_table" "aduca" {
  vpc_id = aws_vpc.aduca.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "aduca-route-table"
  }
}

resource "aws_route_table_association" "aduca" {
  subnet_id      = aws_subnet.aduca.id
  route_table_id = aws_route_table.aduca.id
}
