// Provider

provider "aws" {
  version = "2.33.0"
  region = var.aws_region
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


resource "aws_iam_user" "user" {
  name = "${var.project_name}-svc-user"
}

data "template_file" "bucketpolicy" {
   template = file("policies/bucketpolicy.json")
   vars = {
     bucket_arn = aws_s3_bucket.bucket.arn
     svc_user = aws_iam_user.user.arn
   }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.template_file.bucketpolicy.rendered
}
