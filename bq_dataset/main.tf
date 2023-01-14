resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset
  location   = "asia-southeast1"
  project    = var.service_project
}
