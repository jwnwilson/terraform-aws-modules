# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

resource "aws_vpc_endpoint" "pdf_vpc_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "pdf generation service"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = var.private_subnets
  security_group_ids = [var.default_security_group_id]
}

module "lambda" {
  source                  = "terraform-aws-modules/lambda/aws"

  function_name           = "${var.project}_${var.environment}"
  description             = var.description

  create_package          = false

  image_uri               = "${var.ecr_url}:${var.docker_tag}"
  package_type            = "Image"
  
  vpc_subnet_ids          = var.vpc_subnet_ids
  vpc_security_group_ids  = var.vpc_security_group_ids

  attach_network_policy   = true
  timeout                 = 30

  attach_tracing_policy   = true
  tracing_mode            = "Active"

  # This can be used to reduce the cold starts of lambda
  # provisioned_concurrent_executions = 10
  # publish                 = true

  environment_variables = merge(
    {
      ENVIRONMENT = var.environment
    },
    var.environment_variables,
  )

  # override docker image command to run worker handler
  image_config_command = var.lambda_command

}

# Lambda keep warm events, disabled to aid debugging

# resource "aws_cloudwatch_event_rule" "every_one_minute" {
#   name                = "every-one-minute"
#   description         = "Fires every one minutes"
#   schedule_expression = "rate(1 minute)"
# }

# resource "aws_cloudwatch_event_target" "check_foo_every_one_minute" {
#   rule      = "${aws_cloudwatch_event_rule.every_one_minute.name}"
#   target_id = "lambda"
#   arn       = "${module.lambda.lambda_function_arn}"
# }

# resource "aws_lambda_permission" "allow_cloudwatch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = "${module.lambda.lambda_function_name}"
#   principal     = "events.amazonaws.com"
#   source_arn    = "${aws_cloudwatch_event_rule.every_one_minute.arn}"
# }

resource "aws_iam_policy" "sqs-s3-lambda-policy" {
  name        = "sqs-s3-lambda-policy-${var.project}-${var.environment}"
  description = "allow lambda access to sqs policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sqs-attach" {
  role       = module.lambda.lambda_role_name
  policy_arn = aws_iam_policy.sqs-s3-lambda-policy.arn
}

