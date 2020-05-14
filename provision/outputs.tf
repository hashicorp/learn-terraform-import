output container_name {
  value = docker_container.nginx.name
}

output container_image {
  value = docker_container.nginx.image
}
