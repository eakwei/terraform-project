# creating region
variable "region" {
    description = "AWS-region" 
}

#VPC Tenancy
variable "tenancy" {
    description = "Default tenancy of VPC"
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

# creating instance type
variable instance_type {
    description = "EC2 Instance Type"
}

# creating vpc components
variable "aws_vpc-website-vpc" {
    description = "VPC-cidr_block"
}

# creating public subnet component
variable "pub_sub_cidr" {
    description = "Web Public Subnet 1"
    type = list(string)
}
/*variable "pub_sub_cidr2" {
    description = "Web Public Subnet 2"
    type = string
} */

# creating private subnet component
variable "priv_app_sub_cidr" {
    description = "Application Private Subnet 1"
    type = list(string)
}
/*
variable "priv_app_sub_cidr2" {
    description = "Application Private Subnet 2"
    type = string
} */

#Count variable
variable "item_count" {
  description = "default count used to set AZs and instances"
  type        = number
  default     = 2
}

#Instance variables
variable "ami_id" {
  description = "default ami"
  type        = string
  default     = "ami-06464c878dbe46da4"
}

#Create database variables
variable "rds_instance" {
  type = map(any)
  default = {
    allocated_storage   = 10
    engine              = "mysql"
    engine_version      = "5.7.42"
    instance_class      = "db.t2.micro"
    multi_az            = false
    dbname                = "mysqldb"
    skip_final_snapshot = true
  }
}

#Create database sensitive variables
variable "user_information" {
  type = map(any)
  default = {
    username = "admin"
    password = "admin123"
  }
  sensitive = true
}

variable "ec2_web-security_group" {
  type = list(object({
    from_port = number
    to_port = number
    protocol = string
  }))

  default = [
    {
      from_port = 80
      to_port = 80
      protocol = "tcp"
    },
    {
      from_port = 22
      to_port = 22
      protocol = "tcp"
    }
  ]
}

variable "database-security_group" {
  type = list(object({
    from_port = number
    to_port = number
    protocol = string
  }))

  default = [
    {
      from_port = 80
      to_port = 80
      protocol = "tcp"
    },
    {
      from_port = 22
      to_port = 22
      protocol = "tcp"
    },
    {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
    }
  ]
}