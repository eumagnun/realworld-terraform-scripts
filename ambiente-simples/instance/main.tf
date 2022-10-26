variable "instance_name" {}
variable "instance_zone" {}
variable "instance_type" {
  default = "e2-medium"
}
variable "instance_network" {}
variable "instance_subnet" {}

resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  zone         = var.instance_zone
  machine_type = var.instance_type
  boot_disk {
    initialize_params {
      image = "debian-11-bullseye-v20220920"
    }
  }
  shielded_instance_config {
    enable_secure_boot = true
  }
  network_interface {
    network    = var.instance_network
    subnetwork = var.instance_subnet
    access_config {
      # Allocate a one-to-one NAT IP to the instance
    }

  }
}
