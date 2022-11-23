variable "instance_name" {}
variable "instance_zone" {}
variable "instance_type" {
  default = "e2-medium"
}
variable "instance_network" {}
variable "instance_subnet" {}
variable "instance_network_tag" {}
variable "need_external_ip" {
  default = false
}

resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  zone         = var.instance_zone
  machine_type = var.instance_type
  tags = [var.instance_network_tag]

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
    
    dynamic "access_config" {
      for_each = var.need_external_ip ? [""] : []
      content {}
    }
  }
}
