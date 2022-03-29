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
  for_each     = fileset("~/Documents/2035_gray_host/", "**")
  bucket       = aws_s3_bucket.grayhost.id
  key          = each.value
  content_type = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1])
  source       = "~/Documents/2035_gray_host/${each.value}"
  etag         = filemd5("~Documents/2035_gray_host/${each.value}")
}

#-----------------------------------------------
# CNAME addition
#-----------------------------------------------
resource "aws_route53_record" "cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "grayhost.${data.aws_route53_zone.selected.name}"
  type    = "CNAME"
  ttl     = "5"
  records = [aws_s3_bucket_website_configuration.grayhost.website_endpoint]

}
