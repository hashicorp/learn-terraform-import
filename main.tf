# Configure docker provider
#
# https://www.terraform.io/docs/providers/docker/index.html

terraform {
  required_version = ">= 0.13"

  required_providers {
    docker = {
      source = "terraform-providers/docker"
      version = "2.7.2"
    }
  }
}
