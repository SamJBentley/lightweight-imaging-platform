# Contains code to create the QuPath EC2, its permissions and its firewall

# The security group (i.e. firewall) for the QuPath EC2
# It is open to the world, so you will need to change this to make it more restrictive
resource "aws_security_group" "main-sg" {
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

# The IAM role (i.e. the permissions role) for the QuPath EC2
resource "aws_iam_role" "ec2_role" {
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
}
#
resource "aws_iam_instance_profile" "profile" {
  name = "test_profile"
  role = aws_iam_role.ec2_role.name
}

# The QuPath EC2. The user data script contains powershell code so that it mounts the Storage Gateway as a network drive
resource "aws_instance" "qupath" {
    ami = "ami-09367cb512d8a2ee4"
    instance_type = "t2.xlarge"
    key_name = var.keyPair
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.main-sg.id]
#    iam_instance_profile = aws_iam_instance_profile.profile.name
    user_data = <<EOF
<powershell>
Start-Sleep -s 60
net use D: \\${aws_instance.sgw.private_ip}\${aws_s3_bucket.my-images.bucket} /user:${aws_storagegateway_gateway.gateway.gateway_id}\smbguest ${aws_storagegateway_gateway.gateway.smb_guest_password}
</powershell>
<detach>true</detach>
EOF

    tags = {
      Name = "QuPath EC2"
    }
}