resource "aws_vpc" "website-vpc" {
  cidr_block       = var.aws_vpc-website-vpc
  instance_tenancy = "default"

  tags = {
    Name = "website-vpc"
  }
}
 
resource "aws_subnet" "pub_sub_cidr" {
  count = var.item_count
  vpc_id     = aws_vpc.website-vpc.id
  cidr_block = var.pub_sub_cidr[count.index]
  availability_zone = var.availability_zone_names[count.index]

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

/*resource "aws_subnet" "pub_sub_cidr2" {
  vpc_id     = aws_vpc.website-vpc.id
  cidr_block = var.pub_sub_cidr2
  availability_zone = var.availability_zone_names[1]

  tags = {
    Name = "public-subnet-2"
  }
} */

resource "aws_subnet" "priv_app_sub_cidr" {
  count = var.item_count
  vpc_id     = aws_vpc.website-vpc.id
  cidr_block = var.priv_app_sub_cidr[count.index]
  availability_zone = var.availability_zone_names[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}
/*
resource "aws_subnet" "priv_app_sub_cidr2" {
  vpc_id     = aws_vpc.website-vpc.id
  cidr_block = var.priv_app_sub_cidr2
  availability_zone = var.availability_zone_names[1]

  tags = {
    Name = "private-subnet-2"
  }
} */

#Creating route tables
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.website-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }

  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.website-vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public-route-association" {
  count = var.item_count
  subnet_id      = aws_subnet.pub_sub_cidr[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "private-route-association" {
  count = var.item_count
  subnet_id      = aws_subnet.priv_app_sub_cidr[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.website-vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route" "public-igw-route" {
  route_table_id            = aws_route_table.public-route-table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}

resource "aws_eip" "eip_for_ngw" {
  depends_on  = [aws_internet_gateway.igw]
}

# NAT Gateway #
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip_for_ngw.id
  subnet_id     = aws_subnet.pub_sub_cidr[0].id

  tags = {
    Name = "ngw"
  }
  depends_on                = [aws_internet_gateway.igw]
}

# attaching NGW to the private route table #

resource "aws_route" "ngw" {
  route_table_id         = aws_route_table.private-route-table.id
  gateway_id             = aws_nat_gateway.ngw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Security groups #
resource "aws_security_group" "sec-group" {
  name        = "Web-SG"
  vpc_id      = aws_vpc.website-vpc.id

  dynamic "ingress" {
      for_each = var.ec2_web-security_group
      content {
        from_port = ingress.value["from_port"]
        to_port = ingress.value["to_port"]
        protocol = ingress.value["protocol"]
        cidr_blocks = ["0.0.0.0/0"]
      }
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security group for ec2"
  }
}

# ec2 Instance #
resource "aws_instance" "web_public" {
  ami             = var.ami_id
  count           = var.item_count
  instance_type   = var.instance_type
  key_name        = "keypair-euwest-2"
  subnet_id       = aws_subnet.priv_app_sub_cidr[count.index].id
  availability_zone = var.availability_zone_names[count.index]

  tags = {
    Name = "Web-${count.index + 1}"
  }
}

resource "aws_instance" "app_private" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  count           = var.item_count
  key_name        = "keypair-euwest-2"
  subnet_id       = aws_subnet.priv_app_sub_cidr[count.index].id
  availability_zone = var.availability_zone_names[count.index]

  tags = {
    Name = "App-${count.index + 1}"
  }
}

#Create database
resource "aws_db_instance" "default" {
  allocated_storage      = var.rds_instance.allocated_storage
  db_subnet_group_name   = aws_db_subnet_group.default.id
  engine                 = var.rds_instance.engine
  engine_version         = var.rds_instance.engine_version
  instance_class         = var.rds_instance.instance_class
  multi_az               = var.rds_instance.multi_az
  db_name                = var.rds_instance.dbname
  username               = var.user_information.username
  password               = var.user_information.password
  skip_final_snapshot    = var.rds_instance.skip_final_snapshot
  vpc_security_group_ids = [aws_security_group.database-sg.id]
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.priv_app_sub_cidr[0].id, aws_subnet.priv_app_sub_cidr[1].id]

  tags = {
    Name = "My DB subnet group"
  }
}

#Create Database Security Group
resource "aws_security_group" "database-sg" {
  name        = "Database-SG"
  description = "Allow inbound traffic from Web layer"
  vpc_id      = aws_vpc.website-vpc.id

 dynamic "ingress" {
      for_each = var.database-security_group
      content {
        from_port = ingress.value["from_port"]
        to_port = ingress.value["to_port"]
        protocol = ingress.value["protocol"]
        #cidr_blocks = ["${aws_security_group.sec-group.id}"]
      }
    }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
}