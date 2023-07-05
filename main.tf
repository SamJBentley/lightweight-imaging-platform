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
  vpc_id = "vpc-081f928e4fa54d30c"
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

resource "aws_instance" "sam-sgw-instance" {
    ami = "ami-025cac61c7e308970"
    instance_type = "m5.4xlarge"
    key_name = "3d-slicer-windows22"
    subnet_id = "subnet-03779b65560751f69"
    vpc_security_group_ids = [aws_security_group.sam-sg.id, "sg-0b3a2d178610f76fd"]
    iam_instance_profile = aws_iam_instance_profile.test_profile.name

    tags = {
      Name = "sam-terraform-sgw-test"
      CreatedBy = "Sam"
    }
}

resource "aws_storagegateway_gateway" "gateway" {
  gateway_name       = "sam-sgw"
  gateway_timezone   = "GMT"
  gateway_type       = "FILE_S3"
  gateway_ip_address = aws_instance.sam-sgw-instance.private_ip
  smb_guest_password = "password"
  gateway_vpc_endpoint = "vpce-0c04d17536349f6fa-hcg1ud8k.storagegateway.eu-west-1.vpce.amazonaws.com"
}

resource "aws_instance" "qupath-and-syncback" {
    ami = "ami-09367cb512d8a2ee4"
    instance_type = "t2.xlarge"
    key_name = "3d-slicer-windows22"
    subnet_id = "subnet-03779b65560751f69"
    vpc_security_group_ids = [aws_security_group.sam-sg.id, "sg-0b3a2d178610f76fd"]
    iam_instance_profile = aws_iam_instance_profile.test_profile.name

    tags = {
      Name = "qupath-and-syncback"
      CreatedBy = "Sam"
    }
}

resource "aws_s3_bucket" "sam-bucket" {
  bucket = "sam-sgw-hello-world-test"
  force_destroy = true
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "example-entire-bucket" {
  bucket = aws_s3_bucket.sam-bucket.id
  name   = "EntireBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.test_role.name
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.test_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  })
}