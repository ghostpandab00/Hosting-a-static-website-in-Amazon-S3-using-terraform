#-----------------------------------------------
# s3 bucket creation
#-----------------------------------------------
resource "aws_s3_bucket" "grayhost" {
  bucket = "grayhost.vyshnavlalp.ml"

  tags = {
    "Name" = "grayhost.vyshnavlalp.ml"
  }
}

#-----------------------------------------------
# Enabling static site permission
#-----------------------------------------------
resource "aws_s3_bucket_website_configuration" "grayhost" {
  bucket = aws_s3_bucket.grayhost.bucket

  index_document {
    suffix = "index.html"
  }

}

#-----------------------------------------------
# Attaching policy to s3 bucket
#-----------------------------------------------
resource "aws_s3_bucket_policy" "grayhost-policy" {
  bucket = aws_s3_bucket.grayhost.id
  policy = data.aws_iam_policy_document.grayhost-policy.json

}


#-----------------------------------------------
# Uploading files to s3
#-----------------------------------------------
resource "aws_s3_object" "sitefiles" {
  for_each     = fileset("/home/vyshnavlal/Documents/2035_gray_host/", "**")
  bucket       = aws_s3_bucket.grayhost.id
  key          = each.value
  content_type = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1])
  source       = "~/Documents/2035_gray_host/${each.value}"
  etag         = filemd5("/home/vyshnavlal/Documents/2035_gray_host/${each.value}")
}

#-----------------------------------------------
# Creating CloudFront distribution
#-----------------------------------------------
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "origin-access-identity/${aws_s3_bucket.grayhost.bucket}"

}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.grayhost.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.grayhost.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }

  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution of grayhost.vyshnavlalp.ml"
  default_root_object = "index.html"

  aliases = ["grayhost.vyshnavlalp.ml"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.grayhost.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.grayhost.bucket}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"

    }
  }

  viewer_certificate {
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
    acm_certificate_arn            = "arn:aws:acm:us-east-1:500335039258:certificate/adb96a56-11b8-4eda-a4b6-ecbae993b4bd"
  }
}

#-----------------------------------------------
# CNAME addition
#-----------------------------------------------
resource "aws_route53_record" "cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "grayhost.${data.aws_route53_zone.selected.name}"
  type    = "CNAME"
  ttl     = "5"
  records = [aws_cloudfront_distribution.domain_name]

}

