# Main S3 Bucket Resource
resource "aws_s3_bucket" "s3_bucket" {
  bucket              = var.bucket_name
  tags                = var.tags
  object_lock_enabled = var.object_lock_enabled
  force_destroy       = var.force_destroy
}

# S3 Bucket ACL Configuration
resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  count = var.acl != "disabled" ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = var.acl
}

# S3 Bucket Versioning Configuration
resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Static Website Configuration
resource "aws_s3_bucket_website_configuration" "s3_bucket_website_configuration" {
  count  = var.enable_static_hosting ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }

  dynamic "routing_rule" {
    for_each = var.website_routing_rules
    content {
      condition {
        key_prefix_equals               = lookup(routing_rule.value.condition, "key_prefix_equals", null)
        http_error_code_returned_equals = lookup(routing_rule.value.condition, "http_error_code_returned_equals", null)
      }
      redirect {
        host_name               = lookup(routing_rule.value.redirect, "host_name", null)
        http_redirect_code      = lookup(routing_rule.value.redirect, "http_redirect_code", null)
        protocol                = lookup(routing_rule.value.redirect, "protocol", null)
        replace_key_prefix_with = lookup(routing_rule.value.redirect, "replace_key_prefix_with", null)
        replace_key_with        = lookup(routing_rule.value.redirect, "replace_key_with", null)
      }
    }
  }
}

# S3 Bucket Server Side Encryption Configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_server_side_encryption_configuration" {
  count  = var.enable_sse_kms || var.enable_sse_s3 ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    bucket_key_enabled = var.sse_bucket_key_enabled

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_sse_kms ? "aws:kms" : "AES256"
      kms_master_key_id = var.enable_sse_kms ? (var.sse_kms_key_id != null ? var.sse_kms_key_id : "aws/s3") : null
    }
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_configuration" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  dynamic "rule" {
    for_each = { for idx, val in var.lifecycle_rules : idx => val }
    content {
      status = "Enabled"
      id     = rule.value.id

      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = lookup(transition.value, "days", null)
          date          = lookup(transition.value, "date", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = lookup(expiration.value, "days", null)
          date                         = lookup(expiration.value, "date", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }
    }
  }
}


# S3 Bucket Public Access Block Configuration
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id
  policy = var.bucket_policy
}

# S3 Bucket Logging Configuration
resource "aws_s3_bucket_logging" "s3_bucket_logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket.id

  target_bucket = var.logging_target_bucket_id
  target_prefix = var.logging_target_prefix
}
