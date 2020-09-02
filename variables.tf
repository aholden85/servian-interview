# Deployment-wide variables that define the solution has a whole.
variable "location" {
  type        = string
  default     = "australiasoutheast"
  description = "The location (region) for the solution."
}

# Production PostgreSQL server-related variables.
variable "prod_psql_server_name" {
  type        = string
  default     = "prod-psql"
  description = "The name for the Production PostgreSQL database server."
}

variable "prod_psql_server_login" {
  type        = string
  default     = "postgres"
  description = "The user used to connect to the PostgreSQL database server."
}

# Production Azure Kubernetes Service (AKS) cluster-related variables.
variable "prod_aks_cluster_name" {
  type        = string
  default     = "prod-aks-cluster"
  description = "The name for the Azure Kubernetes Service (AKS) cluster."
}

variable "prod_aks_dns_prefix" {
  type        = string
  default     = "prod-aks-cluster"
  description = "The DNS prefix for hostnames created within the Azure Kubernetes Service (AKS) cluster."
}

variable "prod_aks_node_count" {
  type        = number
  default     = 1
  description = "The number of nodes for the Azure Kubernetes Service (AKS) cluster."
}

# Production Kubernetes (K8S) container and pod-related variables.
variable "prod_k8s_container_image" {
  type        = string
  default     = "docker.pkg.github.com/servian/techchallengeapp/techchallengeapp:latest"
  description = "The path to the image to be used for deploying containers."
}

variable "prod_k8s_container_name" {
  type        = string
  default     = "techchallengeapp"
  description = "The name of the  to the image to be used for deploying containers."
}

variable "prod_k8s_container_label" {
  type        = string
  default     = "TechChallengeApp"
  description = "????"
}

variable "prod_k8s_container_port" {
  type        = number
  default     = 3000
  description = "Number of the port to access on the container. Number must be in the range 1 to 65535."
}
variable "prod_k8s_loadbalancer_port" {
  type        = number
  default     = 80
  description = "Number of the port to access on the container. Number must be in the range 1 to 65535."
}