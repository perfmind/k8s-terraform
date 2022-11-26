terraform {
  required_version = "> 1.0"
  required_providers {
    google      = ">= 4.0.0"
    google-beta = ">= 4.0.0"
  }
  backend "gcs" {
    bucket = "terampil-terraform-state"
    prefix = "state/gke-prod-east-cluster/"
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
  source = "../../modules/vpc"
  project_id = "terampil-education"
  network_name = "vpc-main"
}

module "subnet" {
  source        = "../../modules/subnet"
  host_project  = "terampil-education"
  host_network  = module.network.network_self_link
  subnet_region = "asia-southeast1"
  subnet_name   = "subnet-prod-east-cluster"
  ip_cidr_range = "10.100.16.0/20"
  secondary_ranges = [
    {
      range_name    = "subnet-prod-east-cluster-pods"
      ip_cidr_range = "10.102.0.0/18"
    },
    {
      range_name    = "subnet-prod-east-cluster-services"
      ip_cidr_range = "10.102.64.0/18"
    }
  ]
}

# CLUSTER
module "k8s-cluster" {
  source                = "../../modules/k8s-cluster"
  host_project          = "terampil-education"
  host_network          = "vpc-main"
  service_project       = "terampil-education"
  subnet                = module.subnet.subnet_self_link
  region                = "asia-southeast1"
  cluster_name          = "prod-east-cluster"
  cluster_location      = "asia-southeast1"
  pods_range            = "subnet-prod-east-cluster-pods"
  services_range        = "subnet-prod-east-cluster-services"
  master_range          = "172.16.0.16/28"
  max_cpu               = 32
  max_memory            = 64
  binary_authorization  = "DISABLED"
  autoscaling_profile   = "OPTIMIZE_UTILIZATION"
  nodepool_auto_upgrade = false

  #APP POOL
  app_pools = [
    {
      name         = "main-pool"
      machine_type = "custom-2-${4 * 1024}"
      image_type   = "COS_CONTAINERD"
    },
  ]
}
