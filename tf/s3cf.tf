#
# ACTIVESTORAGE UPLOADS
#

resource "aws_s3_bucket" "uploads-bucket" {
  bucket = "${var.application_name}-${terraform.workspace}-uploads"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["https://${var.application_host}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "uploads-public-read" {
  bucket = aws_s3_bucket.uploads-bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [{
      Sid    = "PublicReadForGetBucketObjects"
      Effect = "Allow"
      Principal = {
        AWS = "*"
      }
      Action = "s3:GetObject"
      Resource = [
        aws_s3_bucket.uploads-bucket.arn,
        "${aws_s3_bucket.uploads-bucket.arn}/*",
      ]
    }]
  })
}


#
# CLIENT (JS/CSS) ASSETS
#

resource "aws_s3_bucket" "client-assets-bucket" {
  bucket = "${var.application_name}-${terraform.workspace}-client-assets"
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 86400
  }
}

resource "aws_s3_bucket_policy" "client-assets-public-read" {
  bucket = aws_s3_bucket.client-assets-bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [{
      Sid       = "PublicReadForGetBucketObjects"
      Effect    = "Allow"
      Principal = { AWS = "*" }
      Action    = "s3:GetObject"
      Resource = [
        aws_s3_bucket.client-assets-bucket.arn,
        "${aws_s3_bucket.client-assets-bucket.arn}/*",
      ]
    }]
  })
}

resource "aws_cloudfront_distribution" "client-assets-cdn" {
  depends_on = [aws_s3_bucket.client-assets-bucket]
  enabled    = true

  origin {
    domain_name = aws_s3_bucket.client-assets-bucket.bucket_domain_name
    origin_id   = "S3-${aws_s3_bucket.client-assets-bucket.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.client-assets-bucket.bucket}"
    compress         = true
    smooth_streaming = false
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
      headers = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
