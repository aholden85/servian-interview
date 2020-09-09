# Some configuration needs to be done here to allow the Kubernetes provider to manage the
# Azure Kubernetes Serice cluster that we provisioned in the aks.tf file.
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  username               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.username
  password               = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

# To pull a Docker image from GitHub Packages, we need to configure a k8s secret.
resource "kubernetes_secret" "github_pull_secret" {
  metadata {
    name = "docker-cfg"
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
    "auths": {
        "${var.image_registry_server}": {
            "auth": "${base64encode("${var.image_registry_username}:${var.image_registry_token}")}"
        }
    }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Because we only want this done once, at the point of environment creation, we can use the kubernetes_job
# resource to run the 'TechChallengeApp updatedb -s' command at the time of 'terraform apply'.
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

          # Although the default entry point is ./TechChallengeApp, I've defined this here for verbosity.
          command = [var.container_entrypoint]

          # The arguments required to seed the pre-created database.
          args = ["updatedb", "-s"]

          # We use environment variables to declare the required values for the application.
          env {
            name = "VTT_DBUSER"
            # Database users must be in the username@host format, at least for Azure-based PostgreSQL servers.
            value = "${azurerm_postgresql_server.pgsql_server.administrator_login}@${azurerm_postgresql_server.pgsql_server.name}"
          }
          env {
            name = "VTT_DBPASSWORD"
            value = random_password.pgsql_password.result
          }
          env {
            name = "VTT_DBNAME"
            value = azurerm_postgresql_database.pgsql_db.name
          }
          env {
            name = "VTT_DBPORT"
            value = var.pgsql_server_port
          }
          env {
            name = "VTT_DBHOST"
            value = azurerm_postgresql_server.pgsql_server.fqdn
          }
          env {
            name = "VTT_LISTENHOST"
            value = "0.0.0.0"
          }
          env {
            name = "VTT_LISTENPORT"
            value = var.container_port
          }
        }

        # This will ensure that the container will not be re-started once it has finished seed-ing.
        restart_policy = "Never"

        # Specify the secret created earlier on to allow pulling the docker image from GitHub Packages.
        image_pull_secrets {
            name = kubernetes_secret.github_pull_secret.metadata.0.name
        }
      }
    }
    # Try to create the container 4 times before failing.
    backoff_limit = 4
  }

  # We want to wait until this job has run before proceeding to the next step - creating the web-serving containers.
  wait_for_completion = true

  # Because we're seeding the database, specify that we need to wait until the database is created before seeding it.
  # Note that we don't NEED to do this, but documentation varies on implicit V explicit dependancies in Terraform,
  # so I wanted to be certain.
  depends_on = [
    azurerm_postgresql_database.pgsql_db
  ]
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

          # Although the default entry point is ./TechChallengeApp, I've defined this here for verbosity.
          command = [var.container_entrypoint]

          # The arguments required to serve the HTTP front-end.
          args = ["serve"]

          # What port will the containers be serving the application on?
          port {
            container_port = var.container_port
          }

          # We use environment variables to declare the required values for the application.
          env {
            name = "VTT_DBUSER"
            # Database users must be in the username@host format, at least for Azure-based PostgreSQL servers.
            value = "${azurerm_postgresql_server.pgsql_server.administrator_login}@${azurerm_postgresql_server.pgsql_server.name}"
          }
          env {
            name = "VTT_DBPASSWORD"
            value = random_password.pgsql_password.result
          }
          env {
            name = "VTT_DBNAME"
            value = azurerm_postgresql_database.pgsql_db.name
          }
          env {
            name = "VTT_DBPORT"
            value = var.pgsql_server_port
          }
          env {
            name = "VTT_DBHOST"
            value = azurerm_postgresql_server.pgsql_server.fqdn
          }
          env {
            name = "VTT_LISTENHOST"
            value = "0.0.0.0"
          }
          env {
            name = "VTT_LISTENPORT"
            value = var.container_port
          }
        }

        # Specify the secret created earlier on to allow pulling the docker image from GitHub Packages.
        image_pull_secrets {
            name = kubernetes_secret.github_pull_secret.metadata.0.name
        }
      }
    }
  }

  # We preferrably want to seed the database before we provision the containers serving the web-app.
  # Note that we don't NEED to do this, but documentation varies on implicit V explicit dependancies in Terraform,
  # so I wanted to be certain.
  depends_on = [
    kubernetes_job.db_seed
  ]
}

# Define a load-balancer service to provide external access to the container-provided front-end, and to load-balance
# traffic between the available nodes.
resource "kubernetes_service" "k8s_loadbalancer" {
  metadata {
    name = "tech-challenge-app"
  }
  spec {
    selector = {
      App = var.container_label
    }

    # Map the publically accessible port to the container's port.
    # In this case tcp/80 to tcp/3000.
    port {
      port        = var.k8s_loadbalancer_port
      target_port = var.container_port
    }

    type = "LoadBalancer"
  }
}

# Provide some final instructions following the completion of the 'terraform apply'.
output "access_instructions" {
  value = "To access the application, please visit http://${kubernetes_service.k8s_loadbalancer.load_balancer_ingress[0].ip}/."
}