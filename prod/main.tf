// Variables
variable "aws_region" {
  type    = string
  default = "us-west-1"
}

// Provider
provider "aws" {
  version = "2.33.0"
  region = var.aws_region
}


// Resources
resource "aws_s3_bucket" "bucket" {
  bucket = "aecworks-bucket-prod"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

 data "template_file" "bucketpolicy" {
   template = file("bucketpolicy.json")

   vars = {
     bucketname = aws_s3_bucket.bucket.bucket
   }
 }


resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.template_file.bucketpolicy.rendered
}

