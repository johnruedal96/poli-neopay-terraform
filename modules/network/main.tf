variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnets CIDR"
  type        = list(string)
}

variable "private_compute_subnets" {
  description = "List of private compute subnets CIDR"
  type        = list(string)
}

variable "private_data_subnets" {
  description = "List of private data subnets CIDR"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "neopay-vpc-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "neopay-igw-${var.environment}"
    Environment = var.environment
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "neopay-public-subnet-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

# Private Compute Subnets
resource "aws_subnet" "private_compute" {
  count             = length(var.private_compute_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_compute_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "neopay-private-compute-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

# Private Data Subnets
resource "aws_subnet" "private_data" {
  count             = length(var.private_data_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "neopay-private-data-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

# NAT Gateway (Elastic IP)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name        = "neopay-nat-eip-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "neopay-nat-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "neopay-public-rt-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "neopay-private-rt-${var.environment}"
    Environment = var.environment
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_compute" {
  count          = length(var.private_compute_subnets)
  subnet_id      = aws_subnet.private_compute[count.index].id
  route_table_id = aws_route_table.private.id
}

# Data Subnets

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_compute_subnet_ids" {
  value = aws_subnet.private_compute[*].id
}

output "private_data_subnet_ids" {
  value = aws_subnet.private_data[*].id
}
