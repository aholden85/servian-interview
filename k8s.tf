provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.prod_k8s_config.0.host
  username               = azurerm_kubernetes_cluster.main.prod_k8s_config.0.username
  password               = azurerm_kubernetes_cluster.main.prod_k8s_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.prod_k8s_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.prod_k8s_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.prod_k8s_config.0.cluster_ca_certificate)
}

resource "kubernetes_deployment" "prod_k8s_deployment" {
  metadata {
    name = "tech-challenge-app"
    labels = {
      App = var.prod_k8s_container_label
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = var.prod_k8s_container_label
      }
    }
    template {
      metadata {
        labels = {
          App = var.prod_k8s_container_label
        }
      }
      spec {
        container {
          image = var.prod_k8s_container_image
          name  = var.prod_k8s_container_name

          port {
            container_port = var.prod_k8s_container_port
          }

          liveness_probe {
            http_get {
              path = "/healthcheck/"
              port = var.prod_k8s_container_port
            }
            #   initial_delay_seconds = 3
            #   period_seconds        = 3
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "prod_k8s_loadbalancer" {
  metadata {
    name = "tech-challenge-app"
  }
  spec {
    selector = {
      App = kubernetes_deployment.prod_k8s_deployment.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = var.prod_k8s_loadbalancer_port
      target_port = var.prod_k8s_container_port
    }

    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = kubernetes_service.prod_k8s_loadbalancer.load_balancer_ingress[0].ip
}