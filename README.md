## Learn Terraform Import

Learn what Terraform import is and how to use it.

Follow along with the [Learn guide](https://learn.hashicorp.com/FIXME) at HashiCorp Learn.

1. Install prerequisites
    1. Terraform
    1. Docker:
        1. Install docker: `brew cask install docker`
        1. Run "Docker" application, use tutorial to make sure it works.
1. Create resources
    1. cd `docker/provision`
    1. `terraform init`
    1. `terraform apply`
    1. Make note of outputs
    1. Run `docker ps` to see the container exists
1. Import resources
    1. cd `../import`
    1. `terraform init`
    1. This is a blank configuration, with just the docker provider configured.
    1. Add empty resource stub to `main.tf` for the container:
    ```
    resource "docker_container" "web" {
    }
    ```
        - Note: The resource name in this configuration does not have to match the other config; that name is internal to terraform.
    1. Run `docker ps` to identify the name of the container you want to import.
        1. Notice that the [docs](https://www.terraform.io/docs/providers/docker/r/container.html) show how to import the container resource, and requires that we know the full image id/sha. In this case, the `docker ps` output shows the short version of the sha, but we can look up the full sha using the name from the output of the `docker ps` command.
    1. Run `terraform import docker_container.web $(docker inspect -f {{.ID}} tutorial)`
    1. Now the container is in your terraform configuration's state.
        1. Run `terraform show` to see it.
    1. Run `terraform plan`
        1. First, terraform plan validates the configuration, then it compares it with state, then it creates a plan to make the state match the configuration.
        1. Sidebar? This is usually in a "forward" direction; write config => plan => apply this time the resource already exists, so we're working backwards: import => plan => write config/plan until errors go away => write config/plan until config matches state => apply
    1. Plan gives errors for the two missing required arguments, image and name.
        1. Note that you can also see the required and optional arguments in the docs
    1. Name is easy; inspect `terraform show` (or in this case `docker ps` shows the name as well: "tutorial")
    1. Use `terraform show` to find the values
        1. Note: You can use `terraform show -json | jq '.values.root_module.resources[] | select(.address == "docker_container.web").values.image'` and similar.
        1. FIXME: ^ Fix ugly jq query?
    1. Add `name` to the block
    1. image is sort of easy. The value from docker is found in `terraform show` as well.
        1. Sidebar? Notice that it's a `sha:` value. This is how docker stores the image ID internally. This will work, but not as nice as using the image tag or name; remember terraform configuration is meant to be human readable.
        1. In the case of docker images, you can get the tag name with `docker image inspect sha256:602e111c06b6934013578ad80554a074049c59441d9bcd963cb4a7feccede7a5 -f {{.RepoTags}}`
        1. You could use this to recreate the `resource "docker_image" "nginx"` block from the `provision` configuration for a nicer and more maintainable configuration.
    1. Add the `sha256` value for the `image` to the block
    1. Now run `terraform plan` note that if we were to apply now, the container would be replaced; this is because our configuration still doesn't match our state.
    1. There are a lot of differences! Look for the difference that will force the container to be replaced; this is the one that will represent an actual "material" change to your infrastructure. (`ports { # forces replacement`)
    1. Add a `ports` section to the config matching the left-hand ("current state") values:
```
ports {
    external = 8000
    internal = 80
    ip       = "0.0.0.0"
    protocol = "tcp"
  }
```
    1. Notice that this doesn't match your `provision` configuration. The original configuration relied on the default values for ip/protocol, but we aren't referencing the original configuration - the resource in question could have been created in any other way.
        - You can look at the docs again to see if some values match the default value and leave them out of the configuration.
    1. Add each of those values to your configuration, making sure the values match as shown:
```
attach = false
logs = false
must_run = true
start = true
```
    1. Notice that running `terraform plan`, it still shows a change; this is because
        - FIXME: Why is this the case? It makes sense intuitively, but I don't know the "technical" reason
        - FIXME: Is this unique to the docker provider, or this particular example? Or is this a common thing people will run into?
        - FIXME: Is this step necessary, or even useful?
    1. Run `terraform apply` and confirm the plan
        - FIXME: Is this always safe, given that it will say the resource will change?
        - NOTE: I thought `terraform refresh` might make the differences go away, but it doesn't.
    1. Run `terraform plan` to see that there are now no changes.
    1. Optional: Run `docker ps` and `open http://0.0.0.0:8000` to verify the app still works.
    1. Run `terraform destroy` to destroy the container.
    1. Run `docker ps` to validate that it was destroyed.
    1. The "provision" directory can be removed; it no longer is the source of truth for your infrastructure.
