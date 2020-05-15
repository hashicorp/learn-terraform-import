# Final Configuration at end of guide

# resource "docker_image" "nginx" {
#   name = "nginx:latest"
# }

# # docker_container.web
# resource "docker_container" "web" {
#   command = [
#     "nginx",
#     "-g",
#     "daemon off;",
#   ]
#   cpu_shares = 0
#   dns        = []
#   dns_opts   = []
#   dns_search = []
#   entrypoint = []
#   env = [
#     "NGINX_VERSION=1.17.10",
#     "NJS_VERSION=0.3.9",
#     "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
#     "PKG_RELEASE=1~buster",
#   ]
#   group_add         = []
#   hostname          = "75278f99c53a"
#   image             = docker_image.nginx.latest
#   ipc_mode          = "private"
#   links             = []
#   log_driver        = "json-file"
#   log_opts          = {}
#   max_retry_count   = 0
#   memory            = 0
#   memory_swap       = 0
#   name              = "hashicorp-learn"
#   network_mode      = "default"
#   privileged        = false
#   publish_all_ports = false
#   read_only         = false
#   restart           = "no"
#   rm                = false
#   shm_size          = 64
#   sysctls           = {}
#   tmpfs             = {}

#   labels {
#     label = "maintainer"
#     value = "NGINX Docker Maintainers <docker-maint@nginx.com>"
#   }

#   ports {
#     external = 8081
#     internal = 80
#     ip       = "0.0.0.0"
#     protocol = "tcp"
#   }
# }
