# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

resource "aws_sqs_queue" "deadletter_queue" {
  name                        = "${var.project}_queue_deadletter_${var.environment}"
  max_message_size            = 2048
  message_retention_seconds   = 86400
  receive_wait_time_seconds   = 10

  tags = {
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "queue" {
  name                        = "${var.project}_queue_${var.environment}"
  visibility_timeout_seconds  = 900
  max_message_size            = 2048
  message_retention_seconds   = 86400
  receive_wait_time_seconds   = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = 4
  })

  tags = {
    Environment = var.environment
  }
}

output "queue_arn" {
  value = aws_sqs_queue.queue.arn
}
