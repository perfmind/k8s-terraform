variable "host_project" {
  type    = string
  default = "fumekiss"
}

variable "service_project" {
  type    = string
  default = "fumekiss"
}

variable "cluster_name" {
  type    = string
  default = "main-cluster"
}

variable "bg_dataset" {
  type    = string
  default = "fk_k8s_metering_dataset"
}
