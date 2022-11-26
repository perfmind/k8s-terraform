variable "host_project" {
  type = string
}

variable "host_network" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_region" {
  type = string
}

variable "ip_cidr_range" {
  type = string
}

variable "secondary_ranges" {
  type    = list(object({ range_name = string, ip_cidr_range = string }))
  default = []
}

variable "subnet_flow_logs" {
  type    = bool
  default = false
}

variable "subnet_flow_logs_interval" {
  type    = string
  default = "INTERVAL_5_SEC"
}

variable "subnet_flow_logs_sampling" {
  type    = string
  default = "0.5"
}

variable "subnet_flow_logs_metadata" {
  type    = string
  default = "INCLUDE_ALL_METADATA"
}

variable "subnet_flow_logs_filter" {
  type    = string
  default = "true"
}
