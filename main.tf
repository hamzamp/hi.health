provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  
}

resource "aws_subnet" "pubsub" {
  cidr_block = "10.0.10.0/24"
  vpc_id = aws_vpc.myvpc.id
  assign_ipv6_address_on_creation = false
  availability_zone = "eu-west-1a"
  depends_on = [aws_vpc.myvpc]
  tags = {
    Name = "Public-Subnet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "privsub" {
  cidr_block = "10.0.20.0/24"
  vpc_id = aws_vpc.myvpc.id
  assign_ipv6_address_on_creation = false
  availability_zone = "eu-west-1b"
  depends_on = [aws_subnet.pubsub]
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_eip" "vpc_lan_natgw" {
  depends_on = [aws_internet_gateway.myigw]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.vpc_lan_natgw.id
  subnet_id     = aws_subnet.privsub.id
}

# Example: Route Table for Private Subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.privsub.id
  route_table_id = aws_route_table.private_route_table.id
}


resource "aws_subnet" "priv2sub" {
  cidr_block = "10.0.30.0/24"
  vpc_id = aws_vpc.myvpc.id
  assign_ipv6_address_on_creation = false
  availability_zone = "eu-west-1c"
  depends_on = [aws_subnet.privsub]
  tags = {
    Name = "private-subnet2"
  }
}
resource "aws_internet_gateway" "myigw" {
  depends_on = [aws_subnet.priv2sub]
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my-internet-gateway"
  }
}


resource "aws_security_group" "sg1" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh,http"
  }
}

resource "aws_security_group" "sg_backend" {
  name        = "allow 3000"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "HTTP"
    from_port = 3000
    protocol = "tcp"
    to_port = 3000
    cidr_blocks = [aws_subnet.privsub.cidr_block]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.privsub.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg2" {
  name        = "dbsec"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "MySQL"
    from_port = 3306
    protocol = "tcp"
    to_port = 3306
    cidr_blocks = [aws_vpc.myvpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysqlsec"
  }
}

resource "tls_private_key" "ec2key_tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2key_pair" {
  key_name   = "ec2key"
  public_key = tls_private_key.ec2key_tls_private_key.public_key_openssh
}

resource "aws_secretsmanager_secret" "ec2key_secrets" {
   name = "key_ec2"
   description = "ec2key_vm_private_key"
}

resource "aws_secretsmanager_secret_version" "ec2key_secrets" {
  secret_id = aws_secretsmanager_secret.ec2key_secrets.id
  secret_string = jsonencode(
   {
    "ec2key_vm_private_key": "${tls_private_key.ec2key_tls_private_key.private_key_pem}"
   }
  )
}

resource "aws_secretsmanager_secret" "rds_password" {
  name = "password_rds"

  tags = {
    Name        = "RDS_Password"
  }
}

resource "aws_secretsmanager_secret_version" "rds_password_version" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.password.result
}

resource "random_password" "password" {
  length           = 20
  special          = false
  upper            = true
  numeric           = true
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret.rds_password.id
}

resource "aws_instance" "frontend" {
  ami = "ami-0eb11ab33f229b26c"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  availability_zone = "eu-west-1a"
  depends_on = [aws_security_group.sg2, aws_instance.backend]
  key_name = aws_key_pair.ec2key_pair.key_name
  subnet_id = "${aws_subnet.pubsub.id}"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  tags = {
    Name = "frontend"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              
              # Clone from GitHub
              sudo git clone https://github.com/hamzamp/hi.health /opt/hi.health

              # build Docker image
              cd /opt/hi.health
              docker build -t frontend -f docker/frontend.Dockerfile .

              # Run Docker container
              sudo docker run -e BACKEND_HOST="${aws_instance.backend.private_ip}" -d -p 80:80 frontend:latest
              EOF
}

resource "aws_instance" "backend" {
  ami = "ami-0eb11ab33f229b26c"
  instance_type = "t2.micro"
  availability_zone = "eu-west-1b"
  #depends_on = [aws_security_group.sg2]
  key_name = aws_key_pair.ec2key_pair.key_name
  subnet_id = "${aws_subnet.privsub.id}"
  vpc_security_group_ids = [aws_security_group.sg_backend.id]
  tags = {
    Name = "backend"
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              
              # Clone from GitHub
              sudo git clone https://github.com/hamzamp/hi.health /opt/hi.health

              # build Docker image
              cd /opt/hi.health
              sudo docker build -t backend -f docker/backend.Dockerfile .

              # Run Docker container
              sudo docker run -e DB_HOST="${aws_db_instance.database.endpoint}" -e DB_DATABASE="app" -e DB_USERNAME="hihealth" -e DB_PASSWORD="${aws_secretsmanager_secret_version.rds_password_version.secret_string}" -d -p 3000:3000 backend:latest
              EOF
}


resource "aws_db_subnet_group" "private" {
  name       = "privatedbsubgroup"
  subnet_ids = [aws_subnet.privsub.id, aws_subnet.priv2sub.id]
  #depends_on = [aws_instance.frontend]

  tags = {
    Name = "My Private DB subnet group"
  }
}

resource "aws_db_instance" "database" {
  depends_on = [aws_db_subnet_group.private]
  db_name = "mydb"
  instance_class = "db.t2.micro"
  allocated_storage = 10
  availability_zone = "eu-west-1b"
  engine = "postgres"
  engine_version = "12.17"
  username = "hihealth"
  password = aws_secretsmanager_secret_version.rds_password_version.secret_string
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.private.name
  port = 5432
  iam_database_authentication_enabled = true
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.myvpc.id
  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}

output "frontend_public_dns" {
  value = aws_instance.frontend.public_dns
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}