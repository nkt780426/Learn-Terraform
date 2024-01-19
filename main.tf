terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "your_aws_region" {
}

variable "your_aws_access_key" {
}

variable "your_aws_secret_key" {
}

variable "your_avaiability_zone" {
}

provider "aws" {
  region     = var.your_aws_region
  access_key = var.your_aws_access_key
  secret_key = var.your_aws_secret_key
}


# 1. Create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "production"
  }
}

# 2. Create internet gateway (mở đường ra internet)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create custom route table (bảng này đi qua internet gateway)
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create subnet
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  # 24 bit đầu là mạng, 8 bit cuối là địa chỉ con của mạng
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}

# 5. Associate subnet with route table (gắn subnet vào route table)
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow port 20, 80, 443
resource "aws_security_group" "allow_tls" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "allow_tls"
  }
}
    # port = 443
    # from_port vaf to_port cho phép định 1 khoảng port
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  # subnet nào có thể tiếp cận được
  cidr_ipv4         = aws_vpc.prod-vpc.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = aws_vpc.prod-vpc.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
    # port = 22 và 80
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"  # Hoặc hạn chế IP range cụ thể
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"  # Hoặc hạn chế IP range cụ thể
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

    # Cho phép mọi địa chỉ ip có thể tiếp cận đến security group này bên ngoài internet
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 7. Create a network interface with an ip in the subnet that create that was create in step 4
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]
}

# 8. Assign an elastic IP to the network interface create in step 7
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# Write public ip to terminal
output "server_public_ip" {
  value = aws_eip.one.public_ip
}

variable "your_key_name" {
}
# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "my-first-terraform" {
  ami           = "ami-04f5097681773b989"
  instance_type = "t2.micro"
  availability_zone = var.your_avaiability_zone

  # Key để ssh vào
  key_name = var.your_key_name

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.test.id
  }

  # cài apache
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt upgrade -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo 'your very first web server > /var/www/html/index.html'
                EOF
  tags ={
    Name = "Web server"
  }
}

output "server_private_ip" {
  value = aws_instance.my-first-terraform.private_ip
}
output "server_ip" {
  value = aws_instance.my-first-terraform.id
}