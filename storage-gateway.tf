# Contains code to create the Storage Gateway, so that objects in S3 can be presented as a file system and mounted in
# the QuPath EC2

# Gives the Storage Gateway an IP address
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.sgw.id
  allocation_id = aws_eip.elastic_ip.id
}

# Creates the EC2 for Storage Gateway
resource "aws_instance" "sgw" {
    ami = "ami-025cac61c7e308970"
    instance_type = "m5.4xlarge"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.main-sg.id]
    iam_instance_profile = aws_iam_instance_profile.profile.name

    tags = {
      Name = "Storage Gateway EC2"
    }
}

# Creates the Storage Gateway.
# !! You should change the password if you want to use this in production !!
resource "aws_storagegateway_gateway" "gateway" {
  gateway_name       = "sam-sgw"
  gateway_timezone   = "GMT"
  gateway_type       = "FILE_S3"
  gateway_ip_address = aws_eip_association.eip_assoc.public_ip
  smb_guest_password = "password"
  gateway_vpc_endpoint = element(aws_vpc_endpoint.sgw.dns_entry, 0)["dns_name"]
}

# Creates a disk for caching
resource "aws_ebs_volume" "cache-disk" {
  availability_zone = "eu-west-1a"
  size              = 150
  type              = "gp3"
}

# Creates a disk for the EC2
resource "aws_volume_attachment" "ebs" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.cache-disk.id
  instance_id = aws_instance.sgw.id
}

# Associates the EC2 disk with the Storage Gateway
data "aws_storagegateway_local_disk" "disk" {
  disk_node   = aws_volume_attachment.ebs.device_name
  gateway_arn = aws_storagegateway_gateway.gateway.arn
}

# Associates the cache disk with Storage Gateway
resource "aws_storagegateway_cache" "cache" {
  disk_id     = data.aws_storagegateway_local_disk.disk.disk_id
  gateway_arn = aws_storagegateway_gateway.gateway.arn
}

# Creates the File Share for Storage Gateway
resource "aws_storagegateway_smb_file_share" "fileshare" {
  authentication = "GuestAccess"
  gateway_arn    = aws_storagegateway_gateway.gateway.arn
  location_arn   = aws_s3_bucket.my-images.arn
  role_arn       = aws_iam_role.fileshare-role.arn
  cache_attributes {
    cache_stale_timeout_in_seconds = 300
  }
}

# Creates the IAM Role, so the file share can access S3
resource "aws_iam_role" "fileshare-role" {
  name = "file-gateway-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "storagegateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

# Creates the permissions policy for the file share
resource "aws_iam_role_policy" "fileshare-policy" {
  name = "fileshare-policy"
  role = aws_iam_role.fileshare-role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                aws_s3_bucket.my-images.arn
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "${aws_s3_bucket.my-images.arn}/*"
            ],
            "Effect": "Allow"
        }
    ]
})
}