output "qupath_ec2_ip" {
  value = "QuPath EC2 IP (put this into your Remote Desktop client, see README for username & password) = ${aws_instance.qupath.public_ip}"
}

output "s3_bucket_name" {
  value = "The S3 bucket name (to push your images into, see README for how) = ${aws_s3_bucket.my-images.bucket}"
}