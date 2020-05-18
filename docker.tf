## Replace this file with your configuration from following the scenario.
##
## Final configuration:
#
# resource "docker_image" "nginx" {
#   name         = "nginx:latest"
# }
#
# resource "docker_container" "web" {
#   name              = "hashicorp-learn"
#   image             = docker_image.nginx.latest
#
#   ports {
#     external = 8081
#     internal = 80
#   }
# }
