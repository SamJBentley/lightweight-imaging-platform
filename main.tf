terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.6.1"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# The input variable, specifying the EC2 key pair, must be passed in as '-v "keyPair=[keypairName]' to terraform
variable "keyPair" {
  type = string
  description = "The EC2 Key pair (see README for how to create this)"
}