data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  dbt_vpc_cidr          = "10.20.0.0/16"
  dbt_public_cidrs      = ["10.20.0.0/24", "10.20.1.0/24"]
  dbt_selected_azs      = slice(data.aws_availability_zones.available.names, 0, length(local.dbt_public_cidrs))
  dbt_public_subnet_map = { for idx, az in local.dbt_selected_azs : az => local.dbt_public_cidrs[idx] }
}

resource "aws_vpc" "dbt" {
  cidr_block           = local.dbt_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${terraform.workspace}-dbt-vpc"
  }
}

resource "aws_internet_gateway" "dbt" {
  vpc_id = aws_vpc.dbt.id

  tags = {
    Name = "${terraform.workspace}-dbt-igw"
  }
}

resource "aws_subnet" "dbt_public" {
  for_each = local.dbt_public_subnet_map

  vpc_id                  = aws_vpc.dbt.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${terraform.workspace}-dbt-public-${each.key}"
  }
}

resource "aws_route_table" "dbt_public" {
  vpc_id = aws_vpc.dbt.id

  tags = {
    Name = "${terraform.workspace}-dbt-public-rt"
  }
}

resource "aws_route" "dbt_public_internet" {
  route_table_id         = aws_route_table.dbt_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dbt.id
}

resource "aws_route_table_association" "dbt_public" {
  for_each = aws_subnet.dbt_public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.dbt_public.id
}
