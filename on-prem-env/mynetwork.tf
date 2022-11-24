# Create the mynetwork network
resource "google_compute_network" "mynetwork" {
  name                    = "mynetwork"
  routing_mode            = "GLOBAL"
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

#start vpn resources
resource "google_compute_subnetwork" "network_subnet1" {
  name          = "ha-vpn-subnet-3"
  ip_cidr_range = "192.168.1.0/24"
  region        = "southamerica-east1"
  network       = google_compute_network.network.id
}

resource "google_compute_subnetwork" "network_subnet2" {
  name          = "ha-vpn-subnet-4"
  ip_cidr_range = "192.168.2.0/24"
  region        = "southamerica-west1"
  network       = google_compute_network.network.id
}

resource "google_compute_ha_vpn_gateway" "ha_gateway2" {
  region  = "southamerica-east1"
  name    = "ha-vpn-2"
  network = google_compute_network.network.id
}

resource "google_compute_router" "router2" {
  name    = "ha-vpn-router2"
  network = google_compute_network.network.name
  bgp {
    asn = 64515
  }
}

resource "google_compute_vpn_tunnel" "tunnel3" {
  name                  = "ha-vpn-tunnel3"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel4" {
  name                  = "ha-vpn-tunnel4"
  region                = "southamerica-east1"
  vpn_gateway           = google_compute_ha_vpn_gateway.ha_gateway2.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.ha_gateway1.id
  shared_secret         = "a secret message"
  router                = google_compute_router.router2.id
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "router2_interface1" {
  name       = "router2-interface1"
  router     = google_compute_router.router2.name
  region     = "southamerica-east1"
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3.name
}

resource "google_compute_router_peer" "router2_peer1" {
  name                      = "router2-peer1"
  router                    = google_compute_router.router2.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface1.name
}

resource "google_compute_router_interface" "router2_interface2" {
  name       = "router2-interface2"
  router     = google_compute_router.router2.name
  region     = "southamerica-east1"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4.name
}

resource "google_compute_router_peer" "router2_peer2" {
  name                      = "router2-peer2"
  router                    = google_compute_router.router2.name
  region                    = "southamerica-east1"
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router2_interface2.name
}
#end vpn resource
