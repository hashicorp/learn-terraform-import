provider "docker" {
  version = "2.7"
}

## After completing the guide, this file will contain a resource like:
#
# resource "docker_container" "web" {
#   name = "tutorial"
#   image = "sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5"
#
#   attach = false
#   logs = false
#   must_run = true
#   start = true
#
#   ports {
#       external = 8000
#       internal = 80
#       ip       = "0.0.0.0"
#       protocol = "tcp"
#     }
# }
