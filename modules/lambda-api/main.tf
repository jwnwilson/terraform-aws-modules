# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

module "lambda" {
  source                  = "terraform-aws-modules/lambda/aws"

  function_name           = "${var.project}_${var.environment}"
  description             = var.description

  create_package          = false

  image_uri               = "${var.ecr_url}:${var.docker_tag}"
  package_type            = "Image"
  
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

resource "aws_cloudwatch_event_rule" "every_one_minute" {
  name                = "every-one-minute"
  description         = "Fires every one minutes"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "check_foo_every_one_minute" {
  rule      = "${aws_cloudwatch_event_rule.every_one_minute.name}"
  target_id = "lambda"
  arn       = "${module.lambda.lambda_function_arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${module.lambda.lambda_function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_one_minute.arn}"
}

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

