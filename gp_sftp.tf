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



variable "logging_role" {
  description = "Optional: IAM role ARN to use for logging. If not provided, one will be created."
  type        = string
  default     = null
}


# Create default logging role only if not provided
resource "aws_iam_role" "default_logging" {
  count = var.logging_role == null ? 1 : 0

  name = "sftp-transfer-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "transfer.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "default_logging_policy" {
  count = var.logging_role == null ? 1 : 0

  name = "sftp-transfer-logging-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_logging" {
  count      = var.logging_role == null ? 1 : 0
  role       = aws_iam_role.default_logging[0].name
  policy_arn = aws_iam_policy.default_logging_policy[0].arn
}


locals {
  effective_logging_role = var.logging_role != null ? var.logging_role : aws_iam_role.default_logging[0].arn
}


resource "aws_transfer_connector" "this" {
  access_role = var.access_role

  sftp_config {
    trusted_host_keys = var.trusted_host_keys
    user_secret_id     = var.user_secret_id
  }

  url            = var.url
  logging_role   = local.effective_logging_role

  tags = var.tags
}