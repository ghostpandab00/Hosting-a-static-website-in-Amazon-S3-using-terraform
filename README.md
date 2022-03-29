Creating S3 bucket and associated resources using Terraform to host a static website
----
## Description
For a long time, S3 has been an excellent choice for hosting static websites, but it's still a hassle to set up manually. To establish and manage users, buckets, certificates, a CDN, and roughly a hundred additional configuration choices, you must navigate through dozens of pages in the AWS Console. It quickly becomes tiresome if you do this repeatedly. Terraform, a well-known "infrastructure as code" tool, allows us to create resources (such as instances, storage buckets, users, rules, and DNS records) .

## Prerequisites
Before we get started you are going to need so basics:

- Basic knowledge of Terraform
- Terraform installed
- Valid AWS IAM user credentials with required access
- A purchased domain

## S3 Static Website Infrastructure
![1](https://user-images.githubusercontent.com/65948438/160647362-df4674d9-fd44-4257-bbf5-fdff3da53595.png)

Hosting a static website on S3 only requires a few components. This setup creates the following resources:

- S3 bucket for the website files
- Cloudfront distribution as CDN
- Route53 records for the given domain


## Setting up our Terraform components
Start by declaring the aws provider, and relevant input variables for authorization.

```
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key

}
```

```
variable "region" {
  default = "<--- 𝘺𝘰𝘶𝘳 𝘳𝘦𝘨𝘪𝘰𝘯 --->"

}

variable "access_key" {
  default = "<--- 𝘺𝘰𝘶𝘳 𝘢𝘤𝘤𝘦𝘴𝘴 𝘬𝘦𝘺 --->"

}

variable "secret_key" {
  default = "<--- 𝘺𝘰𝘶𝘳 𝘴𝘦𝘤𝘳𝘦𝘵 𝘬𝘦𝘺 --->"

}
```

Now we are going to create a S3 bucket called "grayhost.vyshnavlalp.ml" and enable static site permission

```
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
```

Let's create a bucket policy to make the site publically accessible and attach that policy to the bucket we have created.

```
#-----------------------------------------------
# Bucket policy creation
#-----------------------------------------------
data "aws_iam_policy_document" "grayhost-policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]

    }

    actions = ["s3:GetObject", ]

    resources = [
      aws_s3_bucket.grayhost.arn,
    "${aws_s3_bucket.grayhost.arn}/*"]
  }

}
```

```
#-----------------------------------------------
# Attaching policy to s3 bucket
#-----------------------------------------------
resource "aws_s3_bucket_policy" "grayhost-policy" {
  bucket = aws_s3_bucket.grayhost.id
  policy = data.aws_iam_policy_document.grayhost-policy.json

}
```

We need to upload our site files to S3.

```
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
```

Create a Cloudfront distribution with origin set to the above-created bucket and sets up various Cloudfront configurations like cache/restrictions etc. Also load SSL certificate from ACM

```
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
```

Now we can add CNAME entry for our domain to point to to the CloudFront domain by fetching the zone first and adding Route53 record.

```
#-----------------------------------------------
# Fetching route53 zone
#-----------------------------------------------
data "aws_route53_zone" "selected" {
  name         = "vyshnavlalp.ml."
  private_zone = false
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
```

You will get below outputs after configuring the above resources.

```
output "endpoint" {
  value = aws_s3_bucket.grayhost.website_endpoint

}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "website_url" {

  value = "http://${aws_route53_record.cname.name}"

}
```
![2](https://user-images.githubusercontent.com/65948438/160658020-ae03c035-fde3-4d38-8bbb-2079a2465a3d.png)
