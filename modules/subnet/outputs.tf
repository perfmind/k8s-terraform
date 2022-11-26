output "subnet" {
  value       = google_compute_subnetwork.subnetwork
  description = "The created subnet resources"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnetwork.id
  description = "The id of the subnet being created"
}

output "subnet_self_link" {
  value       = google_compute_subnetwork.subnetwork.self_link
  description = "The URI of the subnet being created"
}

output "subnet_ipv6_cidr_range" {
  value       = google_compute_subnetwork.subnetwork.ipv6_cidr_range
  description = "The range of internal IPv6 addresses that are owned by this subnetwork"
}
