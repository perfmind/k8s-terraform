variable "service_project" {
  type = string
}

variable "kms_name" {
  type = string
}

variable "keyring_name" {
  type = string
}

variable "kms_location" {
  type = string
}

variable "rotation_period" {
  type    = string
  default = "7776000s"
}

variable "purpose" {
  type    = string
  default = "ENCRYPT_DECRYPT"
}
