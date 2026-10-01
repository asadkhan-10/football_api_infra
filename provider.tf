terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "terraform-cli"
}

provider "oci" {
  config_file_profile = "DEFAULT"
  region               = "ap-hyderabad-1"
}