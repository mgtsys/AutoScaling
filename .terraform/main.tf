variable "aws_region" {
    type = string
    description = "Enter you region: "
}
variable "access_key" {
    type = string
    description = "Enter you Access Key: "
}
variable "secret_key" {
    type = string
    description = "Enter you Secret Key: "
}
variable "project_name" {
    type = string
    description = "Enter your project-name: "
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws"{
    region = var.aws_region
    access_key = var.access_key
    secret_key = var.secret_key
}

output "project_name" {
    value = var.project_name
}

resource "aws_vpc" "AutoScalingGroup_VPC" {
    cidr_block = "172.26.0.0/17"
    instance_tenancy = "default"
    enable_dns_hostnames = "true"
    tags = {
        Name = "${var.project_name}"
    }
}

resource "aws_subnet" "PublicSubnet1" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    cidr_block = "172.26.1.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-Public-1a"
    }
}

resource "aws_subnet" "PublicSubnet2" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    cidr_block = "172.26.3.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-Public-2b"
    }
}

resource "aws_subnet" "PublicSubnet3" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    cidr_block = "172.26.5.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[2]}"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.project_name}-Public-3c"
    }
}

resource "aws_subnet" "PrivateSubnet1" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    cidr_block = "172.26.2.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    tags = {
        Name = "${var.project_name}-Private-1a"
    }
}

resource "aws_subnet" "PrivateSubnet2" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    cidr_block = "172.26.4.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    tags = {
        Name = "${var.project_name}-Private-2b"
    }
}

resource "aws_subnet" "PrivateSubnet3" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    cidr_block = "172.26.6.0/24"
    availability_zone = "${data.aws_availability_zones.available.names[2]}"
    tags = {
        Name = "${var.project_name}-Private-3c"
    }
}

resource "aws_eip" "eip" {
    vpc = true
    depends_on = [aws_internet_gateway.InternetGateway]
}

resource "aws_nat_gateway" "NATGateway" {
    subnet_id = "${aws_subnet.PublicSubnet1.id}"
    allocation_id = aws_eip.eip.id
    tags = {
        Name = "${var.project_name}-NAT-Gateway"
    }
    depends_on = [
      aws_subnet.PublicSubnet1,
      aws_internet_gateway.InternetGateway
      ]
}

resource "aws_internet_gateway" "InternetGateway" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    tags = {
        Name = "${var.project_name}-igw"
    }
}

resource "aws_route_table" "PublicRouteTable" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.InternetGateway.id}"
    }
    tags = {
        Name = "${var.project_name}-Public-Route-Table"
    }
}
resource "aws_route_table_association" "PublicRouteTableAssociation1" {
    subnet_id = "${aws_subnet.PublicSubnet1.id}"
    route_table_id = "${aws_route_table.PublicRouteTable.id}"
    depends_on = [
      aws_route_table.PublicRouteTable,
      aws_subnet.PublicSubnet1
    ]
}
resource "aws_route_table_association" "PublicRouteTableAssociation2" {
    subnet_id = "${aws_subnet.PublicSubnet2.id}"
    route_table_id = "${aws_route_table.PublicRouteTable.id}"
    depends_on = [
      aws_route_table.PublicRouteTable,
      aws_subnet.PublicSubnet2
    ]
}
resource "aws_route_table_association" "PublicRouteTableAssociation3" {
    subnet_id = "${aws_subnet.PublicSubnet3.id}"
    route_table_id = "${aws_route_table.PublicRouteTable.id}"
    depends_on = [
      aws_route_table.PublicRouteTable,
      aws_subnet.PublicSubnet3
    ]
}

resource "aws_route_table" "PrivateRouteTable" {
    vpc_id = "${aws_vpc.AutoScalingGroup_VPC.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.NATGateway.id}"
    }
    tags = {
        Name = "${var.project_name}-Private-Route-Table"
    }
}
resource "aws_route_table_association" "PrivateRouteTableAssociation1" {
    subnet_id = "${aws_subnet.PrivateSubnet1.id}"
    route_table_id = "${aws_route_table.PrivateRouteTable.id}"
    depends_on = [
      aws_route_table.PrivateRouteTable,
      aws_subnet.PrivateSubnet1
      ]
}
resource "aws_route_table_association" "PrivateRouteTableAssociation2" {
    subnet_id = "${aws_subnet.PrivateSubnet2.id}"
    route_table_id = "${aws_route_table.PrivateRouteTable.id}"
    depends_on = [
      aws_route_table.PrivateRouteTable,
      aws_subnet.PrivateSubnet2
      ]
}
resource "aws_route_table_association" "PrivateRouteTableAssociation3" {
    subnet_id = "${aws_subnet.PrivateSubnet3.id}"
    route_table_id = "${aws_route_table.PrivateRouteTable.id}"
    depends_on = [
      aws_route_table.PrivateRouteTable,
      aws_subnet.PrivateSubnet3
      ]
}