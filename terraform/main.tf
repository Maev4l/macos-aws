// === Terraform boilerplate
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region = var.region
}


// === Dedicated host
// Currently there is no way to create a dedicated host with a Terraform resource,
// so, we workaround this issue with Cloud Formation
resource "aws_cloudformation_stack" "dedicated_host" {
  name = var.dedicated_instance_name
  tags = local.tags

  template_body = jsonencode({
    "Resources" : {
      "DedicatedHost" : {
        "Type" : "AWS::EC2::Host",
        "Properties" : {
          "AutoPlacement" : "on",
          "AvailabilityZone" : var.zone,
          "HostRecovery" : "off",
          "InstanceType" : "mac1.metal"
        }
      }
    },
    "Outputs" : {
      "HostID" : {
        "Description" : "Host ID",
        "Value" : { "Ref" : "DedicatedHost" }
      }
    }
  })
}
// ===

// === Networking
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  tags                 = local.tags
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.zone

  tags = local.tags
}

resource "aws_internet_gateway" "vpc_internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = local.tags
}

resource "aws_route_table" "vpc_public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_internet_gateway.id
  }

  tags = local.tags
}

resource "aws_route_table_association" "vpc_public_route" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.vpc_public_route_table.id
}

resource "aws_security_group" "ssh" {
  name_prefix = "instance-ssh-sg-"
  vpc_id      = aws_vpc.main_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = local.tags
}
// ===


// === Public key
// Upload a public key which will be used by the instance for the SSH connection
data "local_file" "public_key" {
  filename = "${path.module}/../${var.public_key_filename}"
}

resource "aws_key_pair" "ec2_user_key" {
  key_name   = "ec2-user-key"
  public_key = data.local_file.public_key.content
  tags       = local.tags
}
// ===

// === EC2 
// Get the most recent macOS AMI
data "aws_ami" "macos" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "name"
    values = [
      "amzn-ec2-macos-10.15.7-*-*"
    ]
  }
  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

resource "aws_instance" "ec2_instance" {
  ami                         = data.aws_ami.macos.id
  instance_type               = "mac1.metal"
  key_name                    = aws_key_pair.ec2_user_key.key_name
  host_id                     = aws_cloudformation_stack.dedicated_host.outputs["HostID"]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ssh.id]

  tags = local.tags
}
// ===
