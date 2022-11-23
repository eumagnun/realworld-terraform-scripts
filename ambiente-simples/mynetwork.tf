# Create the mynetwork network
resource "google_compute_network" "mynetwork" {
  name                    = "mynetwork"
  auto_create_subnetworks = false
}


resource "google_compute_firewall" "mynetwork-allow-http" {
  name    = "mynetwork-allow-http"
  network = google_compute_network.mynetwork.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "mynetwork-allow-database" {
  name    = "mynetwork-allow-database"
  network = google_compute_network.mynetwork.self_link

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  target_tags = ["database"]
  source_tags = ["web"]
}

resource "google_compute_firewall" "mynetwork-allow-ssh-from-build-vm" {
  name    = "mynetwork-allow-ssh-from-build-vm"
  network = google_compute_network.mynetwork.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["build"]
}

resource "google_compute_firewall" "mynetwork-allow-ssh-from-cloudshell" {
  name    = "mynetwork-allow-ssh-from-cloudshell"
  network = google_compute_network.mynetwork.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_subnetwork" "subnet-southamerica-east1" {
  name          = "subnet-southamerica-east1"
  ip_cidr_range = "10.0.0.0/24"
  region        = "southamerica-east1"
  network       = google_compute_network.mynetwork.id
}


module "backend-vm" {
  source           = "./instance"
  instance_name    = "backend-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "web"
  need_external_ip = true
}

module "database-vm" {
  source           = "./instance"
  instance_name    = "database-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "database"
}

module "frontend-vm" {
  source           = "./instance"
  instance_name    = "frontend-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "web"
  need_external_ip = true
}
  
module "build-vm" {
  source           = "./instance"
  instance_name    = "build-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "build"
}
