# Create the mynetwork1 network
resource "google_compute_network" "mynetwork1" {
  name                    = "mynetwork1"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_firewall" "mynetwork1-allow-http" {
  name    = "mynetwork1-allow-http"
  network = google_compute_network.mynetwork1.self_link

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}



resource "google_compute_firewall" "mynetwork1-allow-ssh-from-build-vm" {
  name    = "mynetwork1-allow-ssh-from-build-vm"
  network = google_compute_network.mynetwork1.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["build"]
}

resource "google_compute_firewall" "mynetwork1-allow-ssh-from-cloudshell" {
  name    = "mynetwork1-allow-ssh-from-cloudshell"
  network = google_compute_network.mynetwork1.self_link

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
  network       = google_compute_network.mynetwork1.id
}

resource "google_compute_router" "my-router" {
  name    = "my-router"
  region  = google_compute_subnetwork.subnet-southamerica-east1.region
  network = google_compute_network.mynetwork1.id

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

module "backend-vm" {
  source           = "./instance"
  instance_name    = "backend-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork1.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "web"
  need_external_ip = true
}

 
module "build-vm" {
  source           = "./instance"
  instance_name    = "build-vm"
  instance_zone    = "southamerica-east1-a"
  instance_network = google_compute_network.mynetwork1.self_link
  instance_subnet  = google_compute_subnetwork.subnet-southamerica-east1.self_link
  instance_network_tag = "build"
}
  
#start vpn resources

resource "google_compute_subnetwork" "mynetwork1_subnet1" {
  name          = "ha-vpn-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "southamerica-east1"
  network       = google_compute_network.mynetwork1.id
}

resource "google_compute_subnetwork" "mynetwork1_subnet2" {
  name          = "ha-vpn-subnet-2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "southamerica-west1"
  network       = google_compute_network.mynetwork1.id
}

resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  region  = "southamerica-east1"
  name    = "ha-vpn-1"
  network = google_compute_network.mynetwork1.id
}


resource "google_compute_router" "router1" {
  name    = "ha-vpn-router1"
  network = google_compute_network.mynetwork1.name
  bgp {
    asn = 64514
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name                  = "ha-vpn-tunnel1"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  #peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name                  = "ha-vpn-tunnel2"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway1.id
  #peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway2.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router1.id
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "router1_interface1" {
  name       = "router1-interface1"
  router     = google_compute_router.router1.name
  region     = "southamerica-east1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "router1-peer1"
  router                    = google_compute_router.router1.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "router1-interface2"
  router     = google_compute_router.router1.name
  region     = "southamerica-east1"
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "router1-peer2"
  router                    = google_compute_router.router1.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}

#end vpn resources
