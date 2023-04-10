terraform {
  required_version = "> 1.0"
  required_providers {
    google      = ">= 4.0.0"
    google-beta = ">= 4.0.0"
  }
  backend "gcs" {
    bucket = "k8s-fk-terraform-state"
    prefix = "state/gke-main-cluster/"
  }
}

provider "google" {
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

provider "google-beta" {
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_client_config" "client" {}
data "google_client_openid_userinfo" "terraform_user" {}

module "network" {
  source       = "../../modules/vpc"
  project_id   = var.host_project
  network_name = "vpc-main"
}

module "subnet" {
  source        = "../../modules/subnet"
  host_project  = var.host_project
  host_network  = module.network.network_self_link
  subnet_region = "asia-southeast1"
  subnet_name   = "subnet-main-cluster"
  ip_cidr_range = "10.100.16.0/20"
  secondary_ranges = [
    {
      range_name    = "subnet-main-cluster-pods"
      ip_cidr_range = "10.102.0.0/18"
    },
    {
      range_name    = "subnet-main-cluster-services"
      ip_cidr_range = "10.102.64.0/18"
    }
  ]
}

# CLUSTER
module "k8s-cluster" {
  source                = "../../modules/k8s-cluster"
  dataset               = "fk_k8s_metering_dataset"
  host_project          = var.host_project
  host_network          = module.network.network_self_link
  service_project       = var.service_project
  subnet                = module.subnet.subnet_self_link
  region                = "asia-southeast1"
  cluster_name          = var.cluster_name
  cluster_location      = "asia-southeast1-b"
  pods_range            = "subnet-main-cluster-pods"
  services_range        = "subnet-main-cluster-services"
  master_range          = "172.16.0.16/28"
  max_cpu               = 32
  max_memory            = 64
  binary_authorization  = "DISABLED"
  autoscaling_profile   = "OPTIMIZE_UTILIZATION"
  nodepool_auto_upgrade = true

  #APP POOL
  app_pools = [
    {
      name         = "main-pool"
      machine_type = "custom-2-${4 * 1024}"
      image_type   = "COS_CONTAINERD"
    },
  ]
}

module "kms" {
  source          = "../../modules/kms"
  kms_name        = "argocd-kms"
  kms_location    = "asia-southeast1"
  service_project = var.service_project
  keyring_name    = "sops-k8s"
  purpose         = "ENCRYPT_DECRYPT"
}
