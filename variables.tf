# Deployment-wide variables that define the solution has a whole.
variable "location" {
  type = string
  # Southeast Asia is used because Australia Southeast is currently not offering PostgreSQL on the free-tier.
  default     = "Southeast Asia"
  description = "The location (region) for the solution."
}

# Service Principal-related variables.
variable "app_name" {
  type        = string
  default     = "app"
  description = "The name for the AzureAD Application object."
}

variable "admin_group_name" {
  type        = string
  default     = "app-admin-group"
  description = "The name for the AzureAD Group `object."
}

# PostgreSQL server and database-related variables
variable "pgsql_server_login" {
  type        = string
  default     = "postgres"
  description = "The user used to connect to the PostgreSQL database server."
}

variable "pgsql_server_port" {
  type        = number
  default     = 5432
  description = "Number of the port to access on the PostgreSQL database server. Number must be in the range 1 to 65535."
}

# Production Azure Kubernetes Service (AKS) cluster-related variables.
variable "aks_cluster_name" {
  type        = string
  default     = "aks-cluster"
  description = "The name for the Azure Kubernetes Service (AKS) cluster."
}

variable "aks_dns_prefix" {
  type        = string
  default     = "aks-cluster"
  description = "The DNS prefix for hostnames created within the Azure Kubernetes Service (AKS) cluster."
}

variable "aks_node_count" {
  type        = number
  default     = 1
  description = "The number of nodes for the Azure Kubernetes Service (AKS) cluster."
}

# Image repository-related variables.
variable "image_registry_server" {
  type        = string
  default     = "docker.pkg.github.com"
  description = "The location where the image will be pulled from, and authenticated against."
}

variable "image_registry_username" {
  type        = string
  description = "The username to auth against the GitHub Packages Registry."
}

variable "image_registry_token" {
  type        = string
  description = "The token to auth against the GitHub Packages Registry."
}

# Docker/container-related variables.
variable "container_replicas" {
  type        = number
  default     = 2
  description = "The number of desired replicas (instances of the app to run simultaneously)."
}

variable "container_entrypoint" {
  type        = string
  default     = "./TechChallengeApp"
  description = "What to run at the start-up of the container."
}

variable "container_image_path" {
  type        = string
  default     = "docker.pkg.github.com/aholden85/servian-interview/techchallengeapp:latest"
  description = "The name of the image to be used for deploying containers."
}

variable "container_image_name" {
  type        = string
  default     = "techchallengeapp"
  description = "The name of the image to be used for deploying containers."
}

variable "container_image_tag" {
  type        = string
  default     = "latest"
  description = "The tag of the image to be used for deploying containers."
}

variable "container_name" {
  type        = string
  default     = "techchallengeapp"
  description = "The name of the deployed containers."
}

variable "container_label" {
  type        = string
  default     = "TechChallengeApp"
  description = "Used to organize and categorize (scope and select) the deployment."
}

variable "container_port" {
  type        = number
  default     = 3000
  description = "Number of the port to access on the container. Number must be in the range 1 to 65535."
}

# Production Kubernetes (K8S) container and pod-related variables.
variable "k8s_loadbalancer_port" {
  type        = number
  default     = 80
  description = "Number of the port to access on the container. Number must be in the range 1 to 65535."
}