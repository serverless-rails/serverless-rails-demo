resource "aws_vpc" "vpc" {
  cidr_block           = "${var.cidr_prefix[terraform.workspace]}.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = terraform.workspace
  }
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 3 + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_db_subnet_group" "default" {
  name       = terraform.workspace
  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name = "${terraform.workspace}-db-subnet-group"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
}

# Route the public subnet traffic through the IGW
resource "aws_route" "outbound" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}
