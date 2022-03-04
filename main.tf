# Configure docker provider
#
# https://www.terraform.io/docs/providers/docker/index.html
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.16"
    }
  }
  required_version = ">= 0.14"
}

provider "docker" {
  # this setting is only needed on Windows; comment it for MacOS
  host    = "npipe:////.//pipe//docker_engine"
}
