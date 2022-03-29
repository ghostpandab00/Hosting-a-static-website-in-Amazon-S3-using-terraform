output "endpoint" {
  value = aws_s3_bucket.grayhost.website_endpoint

}

output "s3_bucket_domain_name" {
  value = aws_s3_bucket.grayhost.bucket_domain_name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "website_url" {

  value = "http://${aws_route53_record.cname.name}"

}
