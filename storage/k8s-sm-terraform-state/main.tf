resource "google_storage_bucket" "default" {
  name          = var.bucket_name
  storage_class = var.storage_class
  location      = var.bucket_location
  project       = var.project_id
  force_destroy = true
}
