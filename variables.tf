variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "project_name" {
    type = string
    default = "aecworks"
}

variable "s3_bucket_names" {
  # https://discuss.hashicorp.com/t/s3-buckets-policies-for-multiple-buckets-using-for-each/4178/3
  type    = set(string)
  default = ["aecworks-bucket-prod", "aecworks-bucket-staging", "aecworks-bucket-local"]
}
