# Deployment of the Servian TechChallengeApp
Hi - this is my work on automating the deployment of the Servian TechChallengeApp, the Git repo of which can be found ***[here][tca-git-repo]***.

## Usage
To deploy the solution, follow these simple steps:

### Clone this repo
Get yourself a copy of all of this Terraform goodness:
```sh
git clone https://github.com/aholden85/servian-interview.git
```

### Login to Azure
Ensure you have logged in to Azure using one of the following methods:
#### Azure CLI
```sh
az login
```
#### Azure Powershell module
```powershell
Connect-AzAccount
```
Also, make sure that you have an active Azure subscription. That could be an issue given that this solution is based upon the Azure platform.
***NOTE:*** I used the free tier excusively to develop this solution, so it can definitely be done.

### Initialise and apply the Terraform configuration.
From within the directory that you've cloned this repo to, issue the following commands.
```sh
terraform init
# Output omitted.

terraform apply
# Output omitted.

Apply complete! Resources: 19 added, 0 changed, 0 destroyed.

Outputs:

access_instructions = To access the application, please visit http://0.0.0.0/.
```

### Access the deployed application.
As you can see in the last line of the `terraform apply` output, a URL will be generated (only with a real IP address) that you can visit to gain access to the deployed web application.

### DESTROY THE SOLUTION
Don't forget to run a `terraform destroy` once you're done, because no one likes unexpected charges!

## Approach
I took the following approach for deploying this software:
* Terraform to define the infrastructure in Azure.
* A PostgreSQL server and database to house the back-end data.
* An Azure Kubernetes Services cluster to house the pods and containers required.
* A Kubernetes job to seed the database.
* A Kubernetes deployment & service to handle the compute requirements.
* A PostgreSQL Server to store the data.

## Technical Challenges
The main challenges of this project were related to working within the confines of a free-tier Azure account. That said, there were several others than hopefully can serve as a lesson to others who may be on the same learning journey as myself.

### Azure Free-tier Limitations
Microsoft recently applied additional limitations on customers using free benefit subscriptions. One such limitation was the ability to create an instance of Azure Database for PostgreSQL. This was addressed by changing the region from `Australia Southeast` to `Southeast Asia`. Reference ***[here][ms-region-issue]***.

### Azure PostgreSQL & VNet Rules
When creating a `azurerm_postgresql_virtual_network_rule`, you must configure `public_network_access_enabled = true` on the `azurerm_postgresql_server` resource. If the variable is set to `false`, then you will receive the following error when running `terraform apply`. Reference ***[here][ms-pgsql-issue]***.
```sh
Error: Error submitting PostgreSQL Virtual Network Rule "pgsql-vnet-rule" (PostgreSQL Server: "pgsql", Resource Group: "rg"): postgresql.VirtualNetworkRulesClient#CreateOrUpdate: Failure sending request: StatusCode=405 -- Original Error: Code="FeatureSwitchNotEnabled" Message="Requested feature is not enabled"
```

### Terraform, Kubernetes, Docker, and GitHub Packages
There were no documented examples for using the Terraform `kubernetes_deployment` resource to deploy containers hosted on `docker.pkg.github.com`. I found that I was able to figure things out, and went with a `kubernetes_secret` resource to auth to Github. I found ***[this specific example][tf-resource-secret]*** from the official documentation of the `kubernetes_secret` resource to be very useful, in addition to ***[this article][git-config-docker]*** on Configuring Docker for use with GitHub Packages.

***Note:*** You will need to follow the instructions ***[here][git-create-token]*** to generate a personal access token (referred to in the Terraform example below as `var.github_personal_access_token`) to allow you to programmatically authenticate with GitHub and pull an image from the image registry. This token will need *at least* the `read:packages` scope to pull the package, but add the `write:packages` scope if you need to push images to your own GitHub Package registry.

For reference, here is how you configure authenticating against GitHub and using a GitHub Packages-hosted container image for a Kubernetes Deployment using Terraform:
```hcl
resource "kubernetes_secret" "github_pull_secret" {
  metadata {
    name = "docker-cfg"
  }
  data = {
    ".dockerconfigjson" = <<DOCKER
{
    "auths": {
        "docker.pkg.github.com": {
            "auth": "${base64encode("${var.github_username}:${var.github_personal_access_token}")}"
        }
    }
}
DOCKER
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_deployment" "k8s_deployment" {
  metadata {
    name = "http-serve"
    labels = {
      App = var.container_label
    }
  }
  spec {
    replicas = var.container_replicas
    selector {
      match_labels = {
        App = var.container_label
      }
    }
    template {
      metadata {
        labels = {
          App = var.container_label
        }
      }
      spec {
        container {
          image = var.container_image_path
          name = var.container_name

          command = [var.container_entrypoint]
          args = ["serve"]

          port {
            container_port = var.container_port
          }

          # Environment variables omitted.
        }

        image_pull_secrets {
            name = kubernetes_secret.github_pull_secret.metadata.0.name
        }
      }
    }
  }
}
```

### GitHub Packages & Data Transfer Limits
Unfortunately, once I had worked out the authentication process for pulling images from 'private' image registries (such as `docker.pkg.github.com`), I found that I was unable to pull the image due to a billing-related error against the Servian organisation/repo/registry. Further reading ***[here][git-packages-billing]*** seems to indicate that this may be related to data transfer limitations on Github accounts. The output of trying to pull the latest `techchallengeapp` docker image can be seen below:
```sh
PS > cat .\TOKEN.txt | docker login https://docker.pkg.github.com -u aholden85 --password-stdin
Login Succeeded
PS > docker pull docker.pkg.github.com/servian/techchallengeapp/techchallengeapp:latest
latest: Pulling from servian/techchallengeapp/techchallengeapp
df20fa9351a1: Pulling fs layer
10fcc070186b: Pulling fs layer
8c81d864b62b: Pulling fs layer
4f50686dad84: Waiting
02206d4836ae: Waiting
81ab3cdbf7ed: Waiting
379ee390761e: Waiting
error pulling image configuration: denied: Encountered a billing-related error. Please verify the billing status for this account.
```

### Building my own Docker image
Despite not being able to pull the `techchallengeapp` docker image from the Servian GitHub Packages image registry, I could still build an image from the `TechChallengeApp.git` file in the code repository. I could then push this image to my own GitHub Packages image registry:
```sh
PS > docker build https://github.com/servian/TechChallengeApp.git -t techchallengeapp:latest
Sending build context to Docker daemon  181.2kB
# Build step output omitted.
Successfully built 679cc453c6d6
Successfully tagged techchallengeapp:latest
SECURITY WARNING: You are building a Docker image from Windows against a non-Windows Docker host. All files and directories added to build context will have '-rwxr-xr-x' permissions. It is recommended to double check and reset permissions for sensitive files and directories.

PS > docker tag 679cc453c6d6 docker.pkg.github.com/aholden85/servian-interview/techchallengeapp:latest

PS > cat .\TOKEN.txt | docker login https://docker.pkg.github.com -u aholden85 --password-stdin
Login Succeeded
PS > docker push docker.pkg.github.com/aholden85/servian-interview/techchallengeapp:latest
The push refers to repository [docker.pkg.github.com/aholden85/servian-interview/techchallengeapp]
ef5c78f50fbe: Pushed
6526159089ac: Pushed
8e69d030f6a3: Pushed
e5d50e27dc9f: Pushed
99520ca6f7a5: Pushed
fa22f72fa2d7: Pushed
50644c29ef5a: Pushed
latest: digest: sha256:82ff8d42e08ae6c10d73126d13bd997cfbfd3f93e7442314be7ad15653812692 size: 1779
```

### Running the database "seed" function
In trying to figure out how to seed the database, I learned about ***[Kubernetes jobs][tf-resource-k8s-job]***. Through the use of the `kubernetes_job` resource, I was able to run up the container and seed the database.
```hcl
resource "kubernetes_job" "db_seed" {
  metadata {
    name = "database-seed"
  }

  spec {
    template {
      metadata {}
      spec {
        container {
          image = var.container_image_path
          name = var.container_name

          command = [var.container_entrypoint]
          args = ["updatedb", "-s"]

          # Environment variables omitted.

        restart_policy = "Never"

        image_pull_secrets {
            name = kubernetes_secret.github_pull_secret.metadata.0.name
        }
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
}
```

> :warning: **NOTE:** Running the database seed function without the `-s` argument would not work regardless of how I formatted the `VTT_DBUSER` variable:
```sh
Dropping and recreating database: database-name
DROP DATABASE IF EXISTS database-name
CREATE DATABASE database-name
WITH
OWNER = postgres@database-server
ENCODING = 'UTF8'
LC_COLLATE = 'en_US.utf8'
LC_CTYPE = 'en_US.utf8'
TABLESPACE = pg_default
CONNECTION LIMIT = -1
TEMPLATE template0;
pq: syntax error at or near "@"
```

## `terraform graph` output
![Convoluted graphical representation of the Terraform deployment](./graph.svg?raw=true)
Generated using `terraform graph | dot -Tsvg > graph.svg`.

## Alternative Solutions
***AKA the ones that didn't make the cut.***

### Automating the builds of Docker images as part of the environment deployment
I figured that the steps from here had to be incorporating the building of an image, and the pushing of this image into an image registry, into the deployment process. My first iteration was using the `local-exec` provider as part of the `azurerm_container_registry` resource:
```hcl
resource "azurerm_container_registry" "acr" {
  name                     = var.acr_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Standard"
  admin_enabled            = false

  provisioner "local-exec" {
    command     = <<DOCKER
docker build ${var.container_image_gitfile} -t ${var.container_image_name}:${var.container_image_tag};
docker tag techchallengeapp ${azurerm_container_registry.acr.login_server}/${var.container_image_name};
docker login ${azurerm_container_registry.acr.login_server} -u "${azuread_service_principal.aks_sp.application_id}" -p "${random_password.aks_sp.result}";
docker push ${azurerm_container_registry.acr.login_server}/${var.container_image_name};
DOCKER
    interpreter = ["PowerShell", "-Command"]
  }
}
```
I was unable to get this to work due to issues with the `service_principal`, and was unable to get past the stage of authenticating to the Azure Container Registry.

### ACR images
Despite the failures outlined in the previous point, I did write config to use an Azure Container Registry created elsewhere in the Terraform stack to pull Docker images. Hopefully someone else can use this:
```hcl
resource "kubernetes_deployment" "k8s_deployment" {
  metadata {
    name = var.k8s_app_name
    labels = {
      App = var.k8s_app_name
    }
  }
  spec {
    replicas = var.k8s_replicas
    selector {
      match_labels = {
        App = var.k8s_app_name
      }
    }
    template {
      metadata {
        labels = {
          App = var.k8s_app_name
        }
      }
      spec {
        container {
          image = "${azurerm_container_registry.acr.login_server}/${var.container_image_name}:${var.container_image_tag}"
          name  = var.k8s_app_name
        }
      }
    }
  }
}
```

## Personal Challenges
I thoroughly enjoyed this project, despite most probably mading it harder than myself due to the reasons below:
* I had never written a Terraform deployment from scratch before this. I had contributed to Terraform scripts as part of a team, but never managed one from snout-to-tail all by myself.
* I had only minimally worked with Azure before, primarily troubleshooting networking and security issues within environments belonging to customers or other teams.
* I had little experience with containerisation technology, other than understanding the concepts for architectural purposes, and had definitely never deployed a single container, let alone the three that make up this deployment.
* I had definitely never built a docker image, or worked with container image registries.

## Technology
The primary technologies used as part of this work are:
* Microsoft Azure
* Hashicorp Terraform
* Kubernetes
* Docker

[tca-git-repo]: <https://github.com/servian/TechChallengeApp>
[tca-git-repo-pull-image]: <https://github.com/servian/TechChallengeApp/blob/master/doc/readme.md#pull-image-from-github-packages>
[ms-region-issue]: <https://social.microsoft.com/Forums/Windows/en-US/e3e7ab8b-a00c-4204-9e9d-7dd7be315516/error-this-subscription-is-restricted-from-provisioning-postgresql-servers-in-this-region-when?forum=AzureDatabaseforPostgreSQL>
[ms-pgsql-issue]: <https://github.com/terraform-providers/terraform-provider-azurerm/issues/6959#issuecomment-632842219>
[tf-resource-secret]: <https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret#username-and-password>
[tf-resource-k8s-job]: <https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/job>
[git-config-docker]: <https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-docker-for-use-with-github-packages>
[git-packages-billing]: <https://docs.github.com/en/github/setting-up-and-managing-billing-and-payments-on-github/about-billing-for-github-packages>
[git-create-token]: <https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token>