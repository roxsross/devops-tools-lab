# provider.tf - Configura el provider de AWS y la versión mínima de Terraform.
# Se usa region us-west-2. Sin backend remoto, el estado se guarda localmente.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
