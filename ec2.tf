terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.6.1"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_security_group" "sam-sg" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "qupath-and-syncback" {
    ami = "ami-09367cb512d8a2ee4"
    instance_type = "t2.xlarge"
    key_name = "qupath"
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.sam-sg.id]
    iam_instance_profile = aws_iam_instance_profile.test_profile.name
    user_data = "net use D: \\\\${aws_instance.sam-sgw-instance.private_ip}\\${aws_s3_bucket.sam-bucket.bucket} /user:${aws_storagegateway_gateway.gateway.gateway_id}\\smbguest ${aws_storagegateway_gateway.gateway.smb_guest_password}\""

    tags = {
      Name = "qupath-and-syncback"
      CreatedBy = "Sam"
    }
}