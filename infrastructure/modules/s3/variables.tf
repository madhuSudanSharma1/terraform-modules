variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed."
  type        = bool
  default     = false
}

variable "object_lock_enabled" {
  description = "Indicates whether this bucket has an Object Lock configuration enabled at creation. Can only be set to true for new buckets. If true, versioning is automatically enabled."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "acl" {
  description = "The canned ACL to apply to the bucket. Valid values are private, public-read, public-read-write, aws-exec-read, authenticated-read, and log-delivery-write."
  type        = string
  default     = "disabled"
}

variable "enable_versioning" {
  description = "A boolean that indicates if versioning should be enabled for the bucket."
  type        = bool
  default     = true
}



variable "enable_static_hosting" {
  description = "A boolean that indicates if static website hosting should be enabled."
  type        = bool
  default     = false
}

variable "index_document" {
  description = "The name of the index document for the website. Used when static hosting is enabled."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The name of the error document for the website. Used when static hosting is enabled."
  type        = string
  default     = "error.html"
}

variable "website_routing_rules" {
  description = "A list of routing rules for website redirects. Each rule can have a condition and a redirect configuration."
  type = list(object({
    condition = optional(object({
      key_prefix_equals             = optional(string)
      http_error_code_returned_equals = optional(string)
    }))
    redirect = object({
      host_name             = optional(string)
      http_redirect_code    = optional(string)
      protocol              = optional(string)
      replace_key_prefix_with = optional(string)
      replace_key_with        = optional(string)
    })
  }))
  default = []
}

variable "enable_sse_kms" {
  description = "A boolean that indicates if S3 Default Server-Side Encryption (SSE-KMS) should be enabled."
  type        = bool
  default     = false
}

variable "enable_sse_s3" {
  description = "A boolean that indicates if S3 Default Server-Side Encryption (SSE-S3) should be enabled."
  type        = bool
  default     = false
}

variable "sse_kms_key_id" {
  description = "The AWS KMS master key ID used for the S3 bucket default encryption. Required if enable_sse_kms is true and you want to use a custom KMS key. If null, AWS managed S3 key (aws/s3) is used with SSE-KMS."
  type        = string
  default     = null
}

variable "sse_bucket_key_enabled" {
  description = "Whether or not to use Amazon S3 Bucket Keys for SSE-KMS. Reduces KMS request costs. Only applicable when enable_sse_kms is true."
  type        = bool
  default     = false
}


variable "lifecycle_rules" {
  description = "A list of objects that define bucket lifecycle rules. Each list entry becomes a rule within the single aws_s3_bucket_lifecycle_configuration resource. Supports transitions and expiration for current object versions."
  type = list(object({
    id                               = string
    filter                           = optional(object({
      prefix = optional(string)
    }))
    transitions                      = optional(list(object({
      days          = optional(number)
      date          = optional(string) # "YYYY-MM-DD"
      storage_class = string # STANDARD_IA, ONEZONE_IA, GLACIER, DEEP_ARCHIVE
    })))
    expiration                       = optional(object({
      days                      = optional(number)
      date                      = optional(string) # "YYYY-MM-DD"
      expired_object_delete_marker = optional(bool)
    }))
  }))
  default = [] 
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket. Defaults to true."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket. Defaults to true."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to true."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public buckets for this bucket. Defaults to true."
  type        = bool
  default     = true
}


variable "bucket_policy" {
  description = "A valid JSON document representing a bucket policy. If null, no bucket policy will be attached."
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "A boolean that indicates if S3 access logging should be enabled."
  type        = bool
  default     = false
}

variable "logging_target_bucket_id" {
  description = "The ID of the bucket that will receive the log objects. Required if enable_logging is true."
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "To specify a key prefix for log objects."
  type        = string
  default     = "log/"
}