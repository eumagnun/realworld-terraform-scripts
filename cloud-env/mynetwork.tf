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
    ports    = ["8080"]
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

resource "google_compute_router" "my-router" {
  name    = "my-router"
  region  = google_compute_subnetwork.subnet-southamerica-east1.region
  network = google_compute_network.mynetwork.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "my-router-nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.my-router.name
  region                             = google_compute_router.my-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_storage_bucket" "frontend-static-site" {
  name          = "frontend-static-site"
  location      = "SOUTHAMERICA-EAST1"
  force_destroy = true

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  cors {
    origin          = ["http://image-store.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_sql_database_instance" "main" {
  name             = "main"
  database_version = "POSTGRES_14"
  region           = "southamerica-east1"

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
  }
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
 
module "build-vm" {
  source           = "./instance"
  instance_name    = "build-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "build"
}
