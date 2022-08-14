variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {}

variable "environment" {}

variable "project" {}

variable "ecr_url" {}

variable "lambda_command" {
  default = ""
}

variable "docker_tag" {
  default = "latest"
}

variable "vpc_subnet_ids" {
  default = ""
}

variable "vpc_security_group_ids" {
  default = ""
}

variable "environment_variables"{
  default = {}
}