provider "aws" {
  region = "us-west-2"
}

provider "random" {}

resource "random_pet" "name" {}

variable "subnet" {
  default = "10.0.0.0/24"
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = "true"
  tags = {
    Name = "${random_pet.name.id}_vpc"
    Env = random_pet.name.id
  }
}

resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet
  map_public_ip_on_launch = "true"
  tags = {
    Name = "${random_pet.name.id}_subnet"
    Env = random_pet.name.id
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${random_pet.name.id}_gw"
    Env = random_pet.name.id
  }
}
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "default route table"
    env = random_pet.name.id
  }
}
resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "allow_web" {
  name = "allow_web"
  description = "Allow inbound web traffic"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "Web from VPC"
    to_port = 80
    from_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_web"
  }
}
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow inbound ssh traffic"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "ssh from VPC"
    to_port = 22
    from_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_key_pair" "ec2key" {
  key_name = "publicKey"
  public_key = file("pubkey")
}

resource "aws_instance" "web" {
  ami = "ami-a0cfeed8"
  instance_type = "t3.micro"
  user_data = file("init-script.sh")
  subnet_id = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.allow_web.id, aws_security_group.allow_ssh.id]
  key_name = aws_key_pair.ec2key.key_name
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = random_pet.name.id
  }
}

output "domain-name" {
  value = aws_instance.web.public_dns
}

output "application-url" {
  value = "${aws_instance.web.public_dns}/index.php"
}
