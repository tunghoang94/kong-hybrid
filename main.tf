# locals {
#     project             = var.gcp_project
    
#     # kong conf
#     kong_cp_name            = "kong-cp"
#     kong_cp_image_taiwan    = "kong-cp-taiwan-1602062265"
#     kong_cp_image_singapore = "kong-cp-singapore-1602062491"
#     kong_cp_ip_taiwan       = "10.140.0.50"
#     kong_cp_ip_singapore    = "10.148.0.50"

#     kong_dp_name            = "kong-dp"
#     kong_dp_image_taiwan    = "kong-dp-taiwan-1602062757"
#     kong_dp_image_singapore = "kong-dp-singapore-1602062987"
#     kong_dp_group           = "kong-dp"
    
#     kong_startup_script    = file("scripts/startup_kong_hybrid.sh")

#     region_taiwan       = "asia-east1"
#     region_singapore    = "asia-southeast1"
#     zone_taiwan         = "asia-east1-a"
#     zone_singapore      = "asia-southeast1-a"
    
#     # lb 
#     lb_name             = "kong-internal-lb"
#     region              = "asia-east1"
#     network             = "default"
#     port                = 80
#     http_health_check   = false
#     custom_labels       = ["ilb"]
# }

# module "kong-hybrid" {
#     source          = "./modules/kong-hybrid"
    
#     gcp_project     = local.project
#     regions         = [local.region_taiwan, local.region_singapore]
#     zones           = [local.zone_taiwan, local.zone_singapore]

#     kong_dp_name    = local.kong_dp_name
#     kong_dp_images  = [local.kong_dp_image_taiwan, local.kong_dp_image_taiwan] 
#     kong_dp_group   = local.kong_dp_group

#     kong_cp_name    = local.kong_cp_name
#     kong_cp_images  = [local.kong_cp_image_taiwan, local.kong_cp_image_singapore]
#     kong_cp_ips     = [local.kong_cp_ip_taiwan, local.kong_cp_ip_singapore]

#     kong_startup_script = local.kong_startup_script
#     network             = local.network

#     lb_name                = local.lb_name
#     service_label          = local.lb_name
#     gcp_network            = local.network
#     health_check_port      = local.port
#     http_health_check      = local.http_health_check
#     target_tags            = [local.lb_name]
#     source_tags            = [local.lb_name]
#     ports                  = [local.port]
# }

resource "google_compute_global_address" "paas-monitor" {
  name = "paas-monitor"
}

resource "google_compute_global_forwarding_rule" "paas-monitor" {
  name       = "paas-monitor-port-80"
  ip_address = "${google_compute_global_address.paas-monitor.address}"
  port_range = "80"
  target     = "${google_compute_target_http_proxy.paas-monitor.self_link}"
}

resource "google_compute_target_http_proxy" "paas-monitor" {
  name    = "paas-monitor"
  url_map = "${google_compute_url_map.paas-monitor.self_link}"
}

resource "google_compute_url_map" "paas-monitor" {
  name        = "paas-monitor"
  default_service = "${google_compute_backend_service.paas-monitor.self_link}"
}

resource "google_compute_backend_service" "paas-monitor" {
  name             = "paas-monitor-backend"
  protocol         = "HTTP"
  port_name        = "paas-monitor"
  timeout_sec      = 10
  session_affinity = "NONE"

  backend {
    group = "${module.instance-group-us-central1.instance_group_manager}"
  }

  backend {
    group = "${module.instance-group-europe-west4.instance_group_manager}"
  }

  backend {
    group = "${module.instance-group-asia-east1.instance_group_manager}"
  }

  health_checks = ["${module.instance-group-us-central1.health_check}"]
}

resource "google_compute_http_health_check" "paas-monitor" {
  name         = "paas-monitor-${var.region}"
  request_path = "/health"

  timeout_sec        = 5
  check_interval_sec = 5
  port               = 1337

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_firewall" "paas-monitor" {
  ## firewall rules enabling the load balancer health checks
  name    = "paas-monitor-firewall"
  network = "default"

  description = "allow Google health checks and network load balancers access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1337"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["paas-monitor"]
}

resource "google_compute_region_instance_group_manager" "paas-monitor" {
  name = "paas-monitor-${var.region}"

  base_instance_name = "paas-monitor-${var.region}"
  region             = "${var.region}"
  instance_template  = "${google_compute_instance_template.paas-monitor.self_link}"

  version {
    name              = "v1"
    instance_template = "${google_compute_instance_template.paas-monitor.self_link}"
  }

  named_port {
    name = "paas-monitor"
    port = 1337
  }

  auto_healing_policies {
    health_check      = "${google_compute_http_health_check.paas-monitor.self_link}"
    initial_delay_sec = 30
  }

  update_strategy = "ROLLING_UPDATE"

  rolling_update_policy {
    type            = "PROACTIVE"
    minimal_action  = "REPLACE"
    max_surge_fixed = 10
    min_ready_sec   = 60
  }
}