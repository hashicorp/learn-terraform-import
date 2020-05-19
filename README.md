## Learn Terraform Import

Learn what Terraform import is and how to use it.

Follow along with the [Learn guide](https://learn.hashicorp.com/FIXME) at HashiCorp Learn.

### Install prerequisites
1. Terraform:
    1. https://www.terraform.io/downloads.html
    1. https://learn.hashicorp.com/terraform/getting-started/install
1. Docker:
    1. If you need to install docker, we recommend you install and run docker desktop for your platform.
    1. https://docs.docker.com/get-docker/
    1. Run "Docker" application, use tutorial to make sure it works.

### Create a docker container

1. Run this docker command to run latest nginx image.

    ```shell
    $ docker run --name hashicorp-learn --detach --publish 8080:80 nginx:latest
    75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1
    ```
1. Verify container is running by running `docker ps` or visiting `0.0.0.0:8080` in your web browser.
    ```shell
    $ docker ps --filter "name=hashicorp-learn"
    CONTAINER ID        IMAGE                                     COMMAND                  CREATED             STATUS              PORTS                     NAMES
    75278f99c53a        nginx:latest                              "nginx -g 'daemon of…"   5 seconds ago       Up 3 seconds        0.0.0.0:8080->80/tcp      hashicorp-learn
    ```

### Import container resource

1. Initialize your workspace with `terraform init`.
1. This directory contains a blank configuration, with just the docker provider configured in `main.tf`.
1. Add empty resource stub to `docker.tf` for the container.
    ```hcl
    resource "docker_container" "web" {}
    ```
1. Run `docker ps` to identify the name of the container you want to import.

    Notice that the [docs](https://www.terraform.io/docs/providers/docker/r/container.html) show how to import the container resource and require that we know the full container ID/sha. The `docker ps` output shows the short version of the container ID/sha. To retrieve the container's full ID, run the following command.

    ```shell
    $ docker inspect -f {{.ID}} hashicorp-learn
    ```

    NOTE: The ID accepted by terraform import varies by resoruce type and is documented in the provider documentation.
1. Run the following command to import the container into Terraform state.

    ```shell
    $ terraform import docker_container.web $(docker inspect -f {{.ID}} hashicorp-learn)
    docker_container.web: Importing from ID "75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1"...
    docker_container.web: Import prepared!
    Prepared docker_container for import
    docker_container.web: Refreshing state... [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]

    Import successful!

    The resources that were imported are shown above. These resources are now in
    your Terraform state and will henceforth be managed by Terraform.
    ```

1. Now the container is in your terraform configuration's state.

    ```shell
    $ terraform show
    ```

1. Run `terraform plan`. Terraform shows errors for missing required arguments (`image`, `name`).

    ```shell
    $ terraform plan

    Error: Missing required argument

    on docker.tf line 1, in resource "docker_container" "web":
    1: resource "docker_container" "web" {}

    The argument "image" is required, but no definition was found.

    Error: Missing required argument

    on docker.tf line 1, in resource "docker_container" "web":
    1: resource "docker_container" "web" {}

    The argument "name" is required, but no definition was found.
    ```

1. There are two approaches to solving this using the `terraform show` command. Either "cherry pick" the required attributes into your configuration, or accept the entire current state from `terraform show` as your configuration. Either way, the process includes several manual steps.

#### Use existing state as configuration

1. Generate configuration and save it in your `docker.tf` file.

    ```shell
    $ terraform show -no-color > docker.tf
    ```

    - Note: will replace the contents of `docker.tf`.
1. Re-run `terraform plan`. Terraform will show warnings and errors about a deprecated argument ('links'), and several read-only arguments (`ip_address`, `network_data`, `gateway`, `ip_prefix_length`, `id`). Remove these properties from your configuration.
1. Re-run `terraform plan`. It should now execute successfully. The plan indicates that Terraform will update in place to add the `attach`, `logs`, `must_run`, and `start` attributes.
1. Notice that the container resource will not be replaced.
    ````shell
    $ terraform plan
    Refreshing Terraform state in-memory prior to plan...
    The refreshed state will be used to calculate this plan, but will not be
    persisted to local or remote state storage.

    docker_container.web: Refreshing state... [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]

    ## Output Truncated

    Plan: 0 to add, 1 to change, 0 to destroy.

    Warning: "links": [DEPRECATED] The --link flag is a legacy feature of Docker. It may eventually be removed.

    on docker.tf line 2, in resource "docker_container" "web":
    2: resource "docker_container" "web" {

    ------------------------------------------------------------------------

    Note: You didn't specify an "-out" parameter to save this plan, so Terraform
    can't guarantee that exactly these actions will be performed if
    "terraform apply" is subsequently run.
    ````
1. Run `terraform apply` to apply the changes. Remember to confirm the run with a `yes`.
    ```shell
    $ terraform apply
    docker_container.web: Refreshing state... [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]

    ## Output Truncated

    Plan: 0 to add, 1 to change, 0 to destroy.

    ## Output Truncated

    docker_container.web: Modifying... [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]
    docker_container.web: Modifications complete after 0s [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]

    Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
    ```

Note - at this point, there are several attributes which can be removed from
`docker.tf`. This is because those attributes are optional, and the values
defined in your configuration are the same as their default values. Which
attributes are optional, and their default values, will vary from provider to
provider, and can be found in the [provider
documentation](https://www.terraform.io/docs/providers/docker/r/container.html#ports-1).


After removing these unnecessary attributes, your configuration might look like
this:

    ```
    resource "docker_container" "web" {
        image             = docker_image.nginx.latest
        name              = "hashicorp-learn"

        ports {
            external = 8080
            internal = 80
        }
    }
    ```

At this point, running `terraform plan` or `terraform apply` should show no
changes, and you can now manage the container with Terraform as you would any
other resource.

If you want to try the "Cherry pick" scenario before moving on, follow these steps, then switch to that approach.

1. Remove everything inside the `"docker_container" "web"` block in `docker.tf`.
1. Run `terraform state rm "docker_container.web"` to remove the container from terraform's state.
1. Run `terraform import docker_container.web $(docker inspect -f {{.ID}} hashicorp-learn)` to import the container again.

Otherwise, proceed with the next step to verify your configuration.

#### Cherry-pick configuration

To cherry pick the correct configuration, first you will need to add the missing required attributes, which caused the errors shown above when you ran `terraform plan`. Terraform can't generate a plan without all of the required attributes for your resource.

First, run `terraform show` to see what the correct values are for the missing
attributes ('image', and 'name').

```shell
$ terraform show
# docker_container.web:
resource "docker_container" "web" {
    command           = [
        "nginx",
        "-g",
        "daemon off;",
    ]

## Output truncated...

image             = "sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5"

## Output truncated...

name              = "hashicorp-learn"

## Output truncated...
```

Copy these values into the `"docker_container" "web"` block in `docker.tf`:

```hcl
resource "docker_container" "web" {
  name              = "hashicorp-learn"
  image             = "sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5"
}
```

```shell
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

## Output truncated...

Terraform will perform the following actions:

  # docker_container.web must be replaced
-/+ resource "docker_container" "web" {
      + attach            = false
      + bridge            = (known after apply)
      ~ command           = [

## Output truncated...

+ labels {
    + label = (known after apply)
    + value = (known after apply)
  }

- ports { # forces replacement
    - external = 8080 -> null
    - internal = 80 -> null
    - ip       = "0.0.0.0" -> null
    - protocol = "tcp" -> null
  }
}

Plan: 1 to add, 0 to change, 1 to destroy.

## Output truncated...
```

Notice that the current configuration does not yet match the existing container, so applying it would destroy the existing container and add a new one with a different configuration, instead of bringing the existing container under Terraform's control.

Specifically, the configuration is missing a value for `ports`, while the values
loaded from state tell us that docker is exposing the container's port 80 as
port 8080 in your host system.

Resolve this by adding a `ports` block to your `docker.tf` file:

```hcl
resource "docker_container" "web" {
  name              = "hashicorp-learn"
  image             = "sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5"

  ports {
    external = 8080
    internal = 80
  }
}
```

You do not need to include values for `ip` or `protocol` because these
attributes are optional, and the current state is the same as their default
values. Which attributes are optional, and their default values, will vary from
provider to provider, and can be found in the [provider
documentation](https://www.terraform.io/docs/providers/docker/r/container.html#ports-1).

Run `terraform plan` now to compare your new configuration to the state you imported earlier:

```shell
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

## Output truncated...

Terraform will perform the following actions:

  # docker_container.web will be updated in-place
  ~ resource "docker_container" "web" {
      + attach            = false
        command           = [
            "nginx",

## Output truncated...

        log_driver        = "json-file"
        log_opts          = {}
      + logs              = false
        max_retry_count   = 0
        memory            = 0
        memory_swap       = 0
      + must_run          = true
        name              = "hashicorp-learn"
        network_data      = [

## Output truncated...

Plan: 0 to add, 1 to change, 0 to destroy.

## Output truncated...
```

Notice that now the container will be updated instead of replaced. However,
there are still several attributes that will be updated when this plan is
applied. In this case, even if you were to add them to `docker.tf`, they will
still show up as an update when you run a new plan. The reason for this is that
these attributes describe how the underlying container is created, rather than
representing configuration options that docker tracks for the container after
being created. Because of this, there were no corresponding properties for
`terraform import` to load into your state that match these attributes. Since
you will be updating the container instead of creating a new one, it is safe to
apply this configuration as-is. In order to understand how each of these
attributes work, you will need to consult the [provider
documentation](https://www.terraform.io/docs/providers/docker/r/container.html#attach),
and have an understanding of the lifecycle of the underlying resource - in this
case, docker containers.

At this point, running `terraform plan` or `terraform apply` should show no
changes, and you can now manage the container with Terraform as you would any
other resource.

If you want to try the "Semi-automatic" scenario before moving on, follow these
steps, then switch to that approach.

1. Remove everything inside the `"docker_container" "web"` block in `docker.tf`.
1. Run `terraform state rm "docker_container.web"` to remove the container from terraform's state.
1. Run `terraform import docker_container.web $(docker inspect -f {{.ID}} hashicorp-learn)` to import the container again.

Otherwise, proceed with the next step to verify your configuration.

### Verify that your infrastructure still works as expected

```shell
$ docker ps --filter "name=hashicorp-learn"
```

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
fac6b3ddb49d        nginx:latest        "nginx -g 'daemon of…"   11 minutes ago      Up 11 minutes       0.0.0.0:8080->80/tcp   hashicorp-learn
```

You can revisit `0.0.0.0:8080` in your web browser to verify that it is still
up. Also note the "Status" - the container has been up and running since it was
created, so you know that it was not restarted when you imported it into
Terraform.

### Manage the container with Terraform

1. In your `docker.tf` file, change the container's external port from `8080` to `8081`.

    ```hcl
    resource "docker_container" "web" {
        name              = "hashicorp-learn"
        image             = "sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5"

        ports {
            external = 8081
            internal = 80
        }
    }
    ```

1. Apply the change. Remember to confirm the run with a `yes`. This should recreate the container with the new port. Any changes to container port will force a replacement.

    ```shell
    $ terraform apply
    docker_container.web: Refreshing state... [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]
    ## Output truncated

    Plan: 1 to add, 0 to change, 1 to destroy.

    ## Output truncated

    docker_container.web: Destroying... [id=75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1]
    docker_container.web: Destruction complete after 1s
    docker_container.web: Creating...
    docker_container.web: Creation complete after 1s [id=023afc10768ab8eeaf646d6a3ac47b52a15af764367ded41702ef9cf5b91a976]

    Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
    ```

1. Verify that the container has been replaced with a new one with the new configuration by running `docker ps` or visiting `0.0.0.0:8081` in your web browser.

    ```shell
    $ docker ps --filter "name=hashicorp-learn"
    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
    023afc10768a        602e111c06b6        "nginx -g 'daemon of…"   3 minutes ago       Up 3 minutes        0.0.0.0:8081->80/tcp   hashicorp-learn
    ```

### Create a `docker_image` resource

In your `docker.tf` file, the Docker container is uses the sha256 hashed value
to specify which image to use. This is how docker stores the image ID
internally, and so `terraform import` loaded the image ID into your state. While
this will work, it is not as human readable as using the image tag or name.

You can add a Terraform resource for the Docker image to your configiration.
There are two ways to approach this. First, you could import the image by id
just as you did for the container resource. However, when we created the
container earlier in this guide, we asked for the image by tag (`nginx:latest`),
rather than by ID. There will only be a single image for a given ID, but the tag
will refer to different images as it is updated by its maintainer in Docker Hub
- Docker's container management service.

To match this intent, add a resource for this image to your configuration.

First, retrieve the image's tag name by running the following
command.

```shell
$ docker image inspect
sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5 -f
{{.RepoTags}}
[nginx:latest]
```

Then, add the following configuration to your docker.tf file and modify your container configuration to represent this image.

```shell
resource "docker_image" "nginx" {
  name         = "nginx:latest"
}
```

Note: Do not replace the reference to the image in the `"docker_container" "web"` yet. If you were to do so now, it would cause the container to be recreated. This is because Terraform does not yet know the id of the image that will be created. Since that ID might not be the same as the current ID, Terraform assumes the resource must be destroyed and added again.

Run `terraform apply` to apply the changes. Remember to confirm the run with a `yes`.

```shell
$ terraform apply
docker_container.web: Refreshing state... [id=023afc10768ab8eeaf646d6a3ac47b52a15af764367ded41702ef9cf5b91a976]

## Output truncated

Apply complete! Resources: 1 added, 0 changed, 0 destroyed!
```

Now that Terraform has created a resource for the image, you can refer to it in your configuration like so:

```hcl
resource "docker_container" "web" {
  name              = "hashicorp-learn"
  image             = docker_image.nginx.latest

# File truncated...
```

Since `docker_image.nginx.latest` will match the hardcoded image ID you replaced, running `terraform apply` at this point should show no changes:

```shell
$ terraform apply
docker_image.nginx: Refreshing state... [id=sha256:9beeba249f3ee158d3e495a6ac25c5667ae2de8a43ac2a8bfd2bf687a58c06c9nginx:latest]
docker_container.web: Refreshing state... [id=edaacfadbe09896bfb872be9c7fadd13c4c7c9a3a9a175f022c8f667cd6e787d]

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

NOTE: It is possible that the image id for the tag "nginx:latest" changed between the time you first created the docker container at the beginning of this guide and when you ran `terraform apply` just now - in that case, the ID would have changed, and the container will be replaced regardless.

### Next Steps

Congratulations — you have imported a resource into Terraform, then configured it using the Terraform CLI.

Destroy the resources you have created in this guide.
1. Run `terraform destroy` to destroy the container. Remember to confirm your run with a `yes`.

    ```shell
    $ terraform destroy
    ```
1. Run `docker ps` to validate that it was destroyed.

    ```shell
    $ docker ps --filter "name=hashicorp-learn"
    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
    ```

Note: Since you added the image to your Terraform configuration as well as the
container, the image will be removed from docker as well as the container. This
is what we intend for this example, but if there were another container uses the
same image, the destroy step would fail. Remember that importing a resource into
Terraform means that Terraform manages the entire lifecycle of the resource,
including destruction.
