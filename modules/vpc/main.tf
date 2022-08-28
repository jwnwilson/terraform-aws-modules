# Complete using this guide:
# https://medium.com/@ilia.lazebnik/simplifying-aws-private-lambda-gateway-vpc-endpoint-association-with-terraform-b379a247afbf

#   If we attach our lambda to a VPC then we have to use a nat gateway for internet access
#   Do not do this as this is expensive.

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project}-vpc-${var.environment}"
  cidr = "10.10.0.0/16"

  azs           = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # Add public_subnets and NAT Gateway to allow access to internet from Lambda
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  private_subnets = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]

  enable_nat_gateway = false
}
