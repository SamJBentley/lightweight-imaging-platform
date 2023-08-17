# Contains code for creating the S3 bucket that images are uploaded to

# Create the S3 bucket. Since S3 buckets need to have a globally unique name, they are suffixed with a timestamp
resource "aws_s3_bucket" "my-images" {
  bucket_prefix = "my-images-"
  force_destroy = true
}

# Applies Intelligent Tiering to the S3 bucket, so automatically apply cost savings. If images have been untouched for
# 125 days they are put into Glacier. If the images have been untouched for 180 days they are put into deep Glacier storage
resource "aws_s3_bucket_intelligent_tiering_configuration" "it-config" {
  bucket = aws_s3_bucket.my-images.id
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