// Provider

provider "aws" {
  version = "2.33.0"
  region = var.aws_region
}

provider "aws" {
  region = "us-east-1"
  alias = "east"
}


// Resources

// User Dev
resource "aws_iam_user" "user_dev" {
  name = "${var.project_name}-dev-svc-user"
}


// User Prod
resource "aws_iam_user" "user_prod" {
  name = "${var.project_name}-prod-svc-user"
}


// Buckets
resource "aws_s3_bucket" "b" {
  for_each = var.s3_bucket_names
  bucket = each.key
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

// Policies
resource "aws_s3_bucket_policy" "bucket_policy" {
  for_each = aws_s3_bucket.b
  bucket = each.key

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "bucketpolicy",
    Statement = [
      {
        Sid       = "S3PublicBlock"
        Effect    = "Deny"
        NotPrincipal = {
          AWS: [
            "arn:aws:iam::245179060882:root",
            "arn:aws:iam::245179060882:user/tf-admin-user",
            "${each.key == "aecworks-bucket-prod" ? aws_iam_user.user_prod.arn : aws_iam_user.user_dev.arn}"
          ]
        }
        Action    = [
          "s3:ListBucket"
        ]
        Resource  = [
          "${each.value.arn}",
        ]
      },
      {
        Sid       = "S3AppManager"
        Effect    = "Allow"
        Principal = {
          // Add Prod user to prod bucket, else dev
          AWS: "${each.key == "aecworks-bucket-prod" ? aws_iam_user.user_prod.arn : aws_iam_user.user_dev.arn}"
        }
        Action    = [
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ]
        Resource  = [
          "${each.value.arn}",
          "${each.value.arn}/*",
        ]
      }
    ]
  })
}

// Domain Certificate
resource "aws_acm_certificate" "cert" {
  provider = aws.east
  domain_name       = "static.aec.works"
  validation_method = "DNS"
  tags = {
    Environment = "production"
  }
  lifecycle {
    create_before_destroy = true
  }
}


// Cloudfront
locals {
  s3_origin_id = "s3_prod_origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.b["aecworks-bucket-prod"].bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true

  aliases = ["static.aec.works"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    compress               = true
    # min_ttl                = 0
    # default_ttl            = 86400
    # max_ttl                = 31536000
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}
