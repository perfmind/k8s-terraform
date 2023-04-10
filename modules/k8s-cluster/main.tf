data "google_compute_network" "host_network" {
  name    = var.host_network
  project = var.host_project
}

data "google_container_engine_versions" "gke_version" {
  location = var.region
  project  = var.host_project
}

data "google_project" "service_project" {
  project_id = var.service_project
}

# create service account for each cluster
resource "google_service_account" "service_account" {
  project    = var.service_project
  account_id = var.cluster_name
}

locals {
  app_pool_names = [for ap in toset(var.app_pools) : ap.name]
  app_pools      = zipmap(local.app_pool_names, tolist(toset(var.app_pools)))

  all_service_account_roles = concat([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader"
  ])
}

resource "google_project_iam_member" "service_account-roles" {
  for_each = toset(local.all_service_account_roles)

  project = var.service_project
  role    = each.value
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account-network_roles" {
  project = var.host_project
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = var.cluster_name
  project  = var.service_project
  location = var.cluster_location

  # terraform recommendation https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#example-usage---with-a-separately-managed-node-pool-recommended
  remove_default_node_pool = true
  initial_node_count       = 1

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  default_max_pods_per_node = 110

  enable_shielded_nodes = true

  binary_authorization {
    evaluation_mode = var.binary_authorization
  }

  release_channel {
    channel = "REGULAR"
  }

  resource_usage_export_config {
    enable_network_egress_metering       = false
    enable_resource_consumption_metering = true

    bigquery_destination {
      dataset_id = var.dataset
    }
  }

  min_master_version = data.google_container_engine_versions.gke_version.default_cluster_version

  addons_config {
    network_policy_config {
      disabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = false
    }
    http_load_balancing {
      disabled = true
    }
  }

  network    = data.google_compute_network.host_network.self_link
  subnetwork = var.subnet

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    services_secondary_range_name = var.services_range
    cluster_secondary_range_name  = var.pods_range
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }

  # https://cloud.google.com/kubernetes-engine/docs/how-to/encrypting-secrets
  dynamic "database_encryption" {
    for_each = var.etcd_encryption == true ? [true] : []
    content {
      state    = "ENCRYPTED"
      key_name = "projects/${var.service_project}/locations/${var.cluster_location}/keyRings/${var.cluster_name}-secrets/cryptoKeys/${var.cluster_name}-secret"
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "19:00"
    }
  }

  # Deprecated in 1.21, removed in 1.25. 
  # pod_security_policy_config {
  #   enabled = var.pod_security_policy
  # }

  vertical_pod_autoscaling {
    enabled = var.vertical_pod_autoscaling
  }

  authenticator_groups_config {
    security_group = "gke-security-groups@qasir.id"
  }

  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      maximum       = var.max_cpu
      minimum       = 1
    }
    resource_limits {
      resource_type = "memory"
      maximum       = var.max_memory
      minimum       = 1
    }

    autoscaling_profile = var.autoscaling_profile

    auto_provisioning_defaults {
      disk_size       = 30
      service_account = google_service_account.service_account.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_range
  }
}

resource "google_container_node_pool" "pool" {
  provider = google
  for_each = local.app_pools
  name     = each.key
  location = var.cluster_location
  project  = var.service_project

  cluster = google_container_cluster.primary.name

  management {
    auto_repair  = true
    auto_upgrade = var.nodepool_auto_upgrade
  }

  initial_node_count = lookup(each.value, "initial_node_count_pool", 1)
  autoscaling {
    min_node_count = lookup(each.value, "min_node_count_pool", 2)
    max_node_count = lookup(each.value, "max_node_count_pool", 100)
  }

  node_config {
    preemptible = lookup(each.value, "preemtible", false)
    image_type  = lookup(each.value, "image_type", "COS")

    machine_type    = lookup(each.value, "machine_type", "n1-standard-1")
    service_account = google_service_account.service_account.email

    disk_size_gb = lookup(each.value, "disk_size_gb", 30)
    disk_type    = lookup(each.value, "disk_type", "pd-standard")

    metadata = {
      disable-legacy-endpoints = "true"
    }

    tags = []

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

}

output "api_ip_addr" {
  value = google_container_cluster.primary.endpoint
}
