## Learn Terraform Import

Learn what Terraform import is and how to use it.

Follow along with the [Learn guide](https://learn.hashicorp.com/FIXME) at HashiCorp Learn.

### Install prerequisites
1. Terraform
1. Docker:
    1. Install docker: `brew cask install docker`
    1. Run "Docker" application, use tutorial to make sure it works.

### Import and orphaned resource
1. Run docker command to run latest nginx image
    ```shell
    $ docker run --name hashicorp-learn --detach --publish 8080:80 nginx:latest
    75278f99c53a6b39e94127d2c25f7dee13f97a4af89c52d74bff9dc783b3cce1
    ```
1. Verify container is running by running `docker ps` or visiting `localhost:8080`.
    ```shell
    $ $ docker ps --filter "name=hashicorp-learn"
    CONTAINER ID        IMAGE                                     COMMAND                  CREATED             STATUS              PORTS                     NAMES
    75278f99c53a        nginx:latest                              "nginx -g 'daemon of…"   5 seconds ago       Up 3 seconds        0.0.0.0:8080->80/tcp      hashicorp-learn
    ```

### Import orphaned resource
1. Initialize your workspace `terraform init`.
1. This is a blank configuration, with just the docker provider configured.
1. Add empty resource stub to `docker.tf` for the container:
    ```hcl
    resource "docker_container" "web" {}
    ```
    **Note:** The resource name in this configuration does not have to match the other config; that name is internal to terraform.
1. Run `docker ps` to identify the name of the container you want to import.
    
    Notice that the [docs](https://www.terraform.io/docs/providers/docker/r/container.html) show how to import the container resource, and requires that we know the full image id/sha. In this case, the `docker ps` output shows the short version of the sha, but we can look up the full sha using the name from the output of the `docker ps` command.
1. Run the following command to import the container into Terraform state. `$(docker inspect -f {{.ID}} hashicorp-learn)` retrieves the container instance's full ID.
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
1. Run `terraform plan`. Terraform complains about missing arguments (`image`, `name`).
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
1. To resolve this, generate configuration code and save it in your `docker.tf` file.
    ```shell
    $ terraform show -no-color > docker.tf
    ```
1. Re-run `terraform plan`. Terraform complains about read only arguments (`ip_address`, `network_data`, `gateway`, `ip_prefix_length`, `id`). Remove these properties from your configuration code.
1. Re-run `terraform plan`. It should now execute successfully. The plan indicates that Terraform will update in place to add the `attach`, `logs`, `must_run`, and `start` attributes. Your container will **not** restart.
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

### Change container ports using Terraform
1. In your `docker.tf` file, change the container's external port from `8080` to `8081`.
    ```hcl
    resource "docker_container" "web" {
        ## file truncated
        ports {
            external = 8081
            internal = 80
            ip       = "0.0.0.0"
            protocol = "tcp"
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
1. Verify the container port has been changed by running `docker ps` or visit `localhost:8081`.
    ```shell
    $ docker ps --filter "name=hashicorp-learn"
    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
    023afc10768a        602e111c06b6        "nginx -g 'daemon of…"   3 minutes ago       Up 3 minutes        0.0.0.0:8081->80/tcp   hashicorp-learn
    ```

## Optional - Create `docker_image` resource
In your `main.tf`, the Docker container is reference a hashed value for its image. This is how docker stores the image ID internally. While this will work, it is not as nice as using the image tag or name.

```hcl
resource "docker_container" "web" {
    ## truncated
    image             = "sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5"
    ## truncated
}
```
You can recreate the Terraform resource for Docker image to make your configuration more user friendly. Retrieve the image's tag name by running the following command.
```shell
$ docker image inspect sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5 -f {{.RepoTags}}
[nginx:latest]
```

Then, add the following configuration to your docker.tf file and modify your container configuration to reference this image.

```shell
resource "docker_image" "nginx" {
  name         = "nginx:latest"
}

resource "docker_container" "web" {
    ## truncated
    image             = docker_image.nginx.latest
    ## truncated
}
```

Run `terraform apply` to apply the changes. Remember to confirm the run with a `yes`.

```shell
$ terraform apply
docker_container.web: Refreshing state... [id=023afc10768ab8eeaf646d6a3ac47b52a15af764367ded41702ef9cf5b91a976]

## Output truncated

Apply complete! Resources: 2 added, 0 changed, 1 destroyed!
```

### Next Steps

Congrats — you have imported a resource into Terraform, then configured it using the Terraform CLI.

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