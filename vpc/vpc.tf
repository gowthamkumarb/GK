resource "aws_vpc" "vpc" {
  cidr_block       = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
 tags = {
    Name = "stage-vpc"
  }
}




resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "stage-igw"
  }
  
}



data "aws_availability_zones" "avai" {
  state = "available"
}

resource "aws_subnet" "public" {
    count = length(data.aws_availability_zones.avai.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.public_cidr,count.index)
  map_public_ip_on_launch = "true"
  availability_zone = element(data.aws_availability_zones.avai.names,count.index)
  tags = {
    Name = "stage-public-${count.index+1}-subnet"
  }
}


resource "aws_subnet" "private" {
    count = length(data.aws_availability_zones.avai.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.private_cidr,count.index)
  map_public_ip_on_launch = "false"
  availability_zone = element(data.aws_availability_zones.avai.names,count.index)
  tags = {
    Name = "stage-private-${count.index+1}-subnet"
  }
}


resource "aws_subnet" "data" {
    count = length(data.aws_availability_zones.avai.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.data_cidr,count.index)
  map_public_ip_on_launch = "false"
  availability_zone = element(data.aws_availability_zones.avai.names,count.index)
  tags = {
    Name = "stage-data-${count.index+1}-subnet"
  }
}


resource "aws_eip" "eip" {
  vpc      = true
    tags = {
    Name = "stage-eip"
  }
}

resource "aws_nat_gateway" "stage-nat-gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "stage-NAT-gw"
  }
 depends_on = [aws_eip.eip]
}


resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

    tags = {
    Name = "stage-public-route"
  }
}

resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.stage-nat-gw.id
  }

    tags = {
    Name = "stage-private-route"
  }
}


resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.public[*].id,count.index)
  route_table_id = aws_route_table.publicroute.id
}

resource "aws_route_table_association" "private" {
    count = length(aws_subnet.private[*].id)
  subnet_id      = element(aws_subnet.private[*].id,count.index)
  route_table_id = aws_route_table.privateroute.id
}

resource "aws_route_table_association" "data" {
    count = length(aws_subnet.data[*].id)
  subnet_id      = element(aws_subnet.data[*].id,count.index)
  route_table_id = aws_route_table.privateroute.id
}