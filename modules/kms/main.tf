resource "google_kms_key_ring" "cluster-keyring" {
  project  = var.service_project
  name     = var.kms_name
  location = var.kms_location # xxx: doesn't support zonal clusters
}

resource "google_kms_crypto_key" "cluster-key" {
  name            = var.kms_name
  key_ring        = google_kms_key_ring.cluster-keyring.self_link
  rotation_period = var.rotation_period
  purpose         = var.purpose
  lifecycle {
    prevent_destroy = true
  }
}

#data "google_project" "service_project" {
#  project_id = var.service_project
#}

#resource "google_kms_crypto_key_iam_binding" "crypto_key" {
#  crypto_key_id = google_kms_crypto_key.cluster-key.id
#  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#  members = [
#    "serviceAccount:service-${data.google_project.service_project.number}@container-engine-robot.iam.gserviceaccount.com"
#  ]
#}
