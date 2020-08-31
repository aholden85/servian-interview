variable "location" {
    type        = string
    default     = "australiasoutheast"
    description = "The location (region) for the solution."
}

variable "psql_server_name" {
    type        = string
    default     = "psql"
    description = "The name for the PostgreSQL database server."
}

variable "psql_login" {
    type        = string
    default     = "postgres"
    description = "The user used to connect to the PostgreSQL database server."
}

variable "k8s_cluster_name" {
    type        = string
    default     = "aks"
    description = "The name for the k8s cluster."
}

variable "k8s_dns_prefix" {
    type        = string
    default     = "aks"
    description = "???"
}

variable "k8s_node_count" {
    type        = number
    default     = 1
    description = "The number of nodes for the k8s cluster."
}