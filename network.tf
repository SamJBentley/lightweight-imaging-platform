# Contains code to create the VPC (i.e. the network that the deployed components are on)

# The VPC (i.e. AWS network for the deployed components)
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Creates a network endpoint for the Storage Gateway
resource "aws_vpc_endpoint" "sgw" {
  vpc_id       = aws_vpc.vpc.id
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.eu-west-1.storagegateway"
  security_group_ids = [aws_security_group.main-sg.id]
  private_dns_enabled = true
  subnet_ids = [aws_subnet.private.id]
}

# Creates an internet gateway, allowing internet access to the network
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

# Creates an elastic IP, so that the deployed components (i.e. the QuPath EC2) can be accessed from the internet
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.ig]
}

# Applies elastic IPs to the CPV
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
}

# Creates a NAT Gateway, so that components in private subnets can access external services outside of the network
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]
}

# The public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
}

# The private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1a"
}

# The route table for the public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

# The route table for the private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

# Routes for the public route table
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Routes for the private route table
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associates the public route table with the public subnet
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Associates the private route table with the private subnet
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

# The security group (i.e. firewall) for the network
resource "aws_security_group" "default" {
  name        = "default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
}