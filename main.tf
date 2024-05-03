# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "docker" {
  # Comment this setting out if using MacOS
  host = "unix:///var/run/docker.sock"
}
