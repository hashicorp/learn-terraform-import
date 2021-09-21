# Configure docker provider
#
# https://www.terraform.io/docs/providers/docker/index.html
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.11"
    }
  }
  required_version = ">= 0.14"
}
