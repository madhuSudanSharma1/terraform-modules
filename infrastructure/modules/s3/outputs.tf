output "bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.s3_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.s3_bucket.arn
}

output "bucket_domain_name" {
  description = "The S3 bucket regional domain name. When using this output with a CNAME, use the `s3_bucket_website_endpoint` output if website hosting is enabled."
  value       = aws_s3_bucket.s3_bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The S3 bucket regional domain name. The domain name includes the bucket name and the region name. Example: `my-bucket.s3.us-west-1.amazonaws.com`."
  value       = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
}

output "s3_bucket_website_endpoint" {
  description = "The S3 static website hosting endpoint. This is only available if static website hosting is enabled."
  value       = var.enable_static_hosting ? aws_s3_bucket_website_configuration.s3_bucket_website_configuration[0].website_endpoint : null
}

output "s3_bucket_website_domain" {
  description = "The S3 static website hosting domain. This is only available if static website hosting is enabled. This is used to create Route 53 alias records."
  value       = var.enable_static_hosting ? aws_s3_bucket_website_configuration.s3_bucket_website_configuration[0].website_domain : null
}