resource "aws_transfer_connector" "this" {
  access_role = var.access_role

  sftp_config {
    trusted_host_keys = var.trusted_host_keys
    user_secret_id     = var.user_secret_id
  }

  url = var.url

  dynamic "logging_role" {
    for_each = var.logging_role != null ? [1] : []
    content {
      logging_role = var.logging_role
    }
  }

  dynamic "security_policy_name" {
    for_each = var.security_policy_name != null ? [1] : []
    content {
      security_policy_name = var.security_policy_name
    }
  }

  tags = var.tags
}



variable "access_role" {
  description = "ARN of the IAM role with access permissions"
  type        = string
}

variable "trusted_host_keys" {
  description = "SSH public host keys of the SFTP server"
  type        = list(string)
}

variable "user_secret_id" {
  description = "ID of the AWS Secrets Manager secret with SFTP user credentials"
  type        = string
}

variable "url" {
  description = "SFTP server URL"
  type        = string
}

variable "logging_role" {
  description = "IAM Role used for enabling CloudWatch logging"
  type        = string
  default     = null
}

variable "security_policy_name" {
  description = "Security policy to apply to the connector"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to assign to the connector"
  type        = map(string)
  default     = {}
}


output "connector_id" {
  description = "The ID of the SFTP connector"
  value       = aws_transfer_connector.this.id
}