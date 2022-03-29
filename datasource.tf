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

#-----------------------------------------------
# Fetching route53 zone
#-----------------------------------------------
data "aws_route53_zone" "selected" {
  name         = "vyshnavlalp.ml."
  private_zone = false
}

