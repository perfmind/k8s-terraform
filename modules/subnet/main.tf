resource "google_compute_subnetwork" "subnetwork" {
  project                    = var.host_project
  region                     = var.subnet_region
  name                       = var.subnet_name
  ip_cidr_range              = var.ip_cidr_range
  network                    = var.host_network
  private_ip_google_access   = true
  private_ipv6_google_access = "DISABLE_GOOGLE_ACCESS"
  secondary_ip_range         = var.secondary_ranges

  dynamic "log_config" {
    for_each = var.subnet_flow_logs == true ? [true] : []
    content {
      aggregation_interval = var.subnet_flow_logs_interval
      flow_sampling        = var.subnet_flow_logs_sampling
      metadata             = var.subnet_flow_logs_metadata
      filter_expr          = var.subnet_flow_logs_filter
    }
  }
}
