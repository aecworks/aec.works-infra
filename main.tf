// Provider
provider "aws" {
  version = "2.33.0"
  region = var.aws_region
}


// Templates
data "template_file" "rolepolicy" {
   template = file("rolepolicy.json")
   vars = {
     arn_gtalarico = "arn:aws:iam::245179060882:root"
   }
}

data "template_file" "bucketpolicy" {
   template = file("bucketpolicy.json")
   vars = {
     bucket_arn = aws_s3_bucket.bucket.arn
     svc_role_arn = aws_iam_role.role.arn
   }
}


// Resources

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project_name}-prod"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.template_file.bucketpolicy.rendered
}

resource "aws_iam_role" "role" {
  name = "${var.project_name}-svc-role"
  assume_role_policy = data.template_file.rolepolicy.rendered
}
