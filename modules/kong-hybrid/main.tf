terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

locals {
    backends = [
        {
            description = "Instance group for internal-load-balancer"
            group       = google_compute_region_instance_group_manager.kong-dp-group-region1.instance_group
        },
        {
            description = "Instance group for internal-load-balancer"
            group       = google_compute_region_instance_group_manager.kong-dp-group-region2.instance_group
        }
    ]
}

resource "random_string" "vm-name" {
  length  = 4
  upper   = false
  number  = false
  lower   = true
  special = false
}

# KONG CONTROL PLANE
resource "google_compute_instance" "kong-cp-region1" {
    project      = var.gcp_project
    zone         = var.zones[0]
    name         = "${var.kong_cp_name}-${var.regions[0]}-${random_string.vm-name.result}"
    machine_type = var.machine_type

    tags = ["kong-cp", "kong-firewall", "bastion-access"]

    boot_disk {
        initialize_params {
            image = var.kong_cp_images[0]
        }
    }

    // Local SSD disk
    scratch_disk {
        interface = "SCSI"
    }

    network_interface {
        network = var.network
        subnetwork = var.sub_networks[0]
        network_ip = var.kong_cp_ips[0]

        access_config {
            // Ephemeral IP
        }
    }

    scheduling {
        preemptible = true
        automatic_restart = false
        on_host_maintenance = "TERMINATE"
    }

    metadata_startup_script = var.kong_startup_script
}

resource "google_compute_instance" "kong-cp-region2" {
    project      = var.gcp_project
    zone         = var.zones[1]
    name         = "${var.kong_cp_name}-${var.regions[1]}-${random_string.vm-name.result}"
    machine_type = var.machine_type

    tags = ["kong-cp", "kong-firewall", "bastion-access"]

    boot_disk {
        initialize_params {
            image = var.kong_cp_images[1]
        }
    }

    // Local SSD disk
    scratch_disk {
        interface = "SCSI"
    }

    network_interface {
        network = var.network
        subnetwork = var.sub_networks[1]
        network_ip = var.kong_cp_ips[1]

        access_config {
            // Ephemeral IP
        }
    }

    scheduling {
        preemptible = true
        automatic_restart = false
        on_host_maintenance = "TERMINATE"
    }

    metadata_startup_script = var.kong_startup_script
}

# KONG ADMIN
resource "google_compute_instance" "kong-admin" {
    project      = var.gcp_project
    zone         = var.zones[0]
    name         = "kong-admin"
    machine_type = var.machine_type

    tags = ["kong-admin", "kong-firewall", "bastion-access"]

    boot_disk {
        initialize_params {
            image = var.kong_admin_image
        }
    }

    // Local SSD disk
    scratch_disk {
        interface = "SCSI"
    }

    network_interface {
        network = var.network
        subnetwork = var.sub_networks[0]
        access_config {
            // Ephemeral IP
        }
    }

    scheduling {
        preemptible = true
        automatic_restart = false
        on_host_maintenance = "TERMINATE"
    }

    metadata_startup_script = var.kong_admin_startup_script
}

resource "google_compute_instance_template" "kong-dp-instance-template-region1" {
    name         = "kong-dp-instance-template-region1"
    machine_type = var.machine_type
    region       = var.regions[0]
    tags         = ["kong-dp", "kong-firewall", "bastion-access"]
    // boot disk
    disk {
        source_image = var.kong_dp_images[0]
    }

    // networking
    network_interface {
        network = var.network
        subnetwork = var.sub_networks[0]
    }

    lifecycle {
        create_before_destroy = true
    }

    metadata_startup_script = var.kong_startup_script
}

resource "google_compute_instance_template" "kong-dp-instance-template-region2" {
    name         = "kong-dp-instance-template-region2"
    machine_type = var.machine_type
    region       = var.regions[1]
    tags         = ["kong-dp", "kong-firewall", "bastion-access"]
    // boot disk
    disk {
        source_image = var.kong_dp_images[1]
    }

    // networking
    network_interface {
        network = var.network
        subnetwork = var.sub_networks[1]
    }

    lifecycle {
        create_before_destroy = true
    }

    metadata_startup_script = var.kong_startup_script
}

resource "google_compute_region_instance_group_manager" "kong-dp-group-region1" {
    name               = "kong-dp-${var.regions[0]}"
    base_instance_name = "kong-dp-${var.regions[0]}"
    region             = var.regions[0]

    version {
        instance_template  = google_compute_instance_template.kong-dp-instance-template-region1.self_link
    }

    target_size  = 1
    
    auto_healing_policies {
        health_check      = google_compute_health_check.kong-dp-health-check.id
        initial_delay_sec = 300
    }
}

resource "google_compute_region_instance_group_manager" "kong-dp-group-region2" {
    name               = "kong-dp-${var.regions[1]}"
    base_instance_name = "kong-dp-${var.regions[1]}"
    region             = var.regions[1]

    version {
        instance_template  = google_compute_instance_template.kong-dp-instance-template-region2.self_link
    }

    target_size  = 1
    
    auto_healing_policies {
        health_check      = google_compute_health_check.kong-dp-health-check.id
        initial_delay_sec = 300
    }
}

# KONG COMMON
resource "google_compute_firewall" "kong-firewall" {
    project    = var.gcp_project
    name       = "kong-firewall"
    network    = var.network
    target_tags = ["kong-firewall"]

    allow {
        protocol = "icmp"
    }
    
    allow {
        protocol = "tcp"
        ports    = ["22", "80", "443"]
    }
}

resource "google_compute_health_check" "kong-dp-health-check" {
  name                = "kong-dp-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port         = "80"
  }
}

resource "google_compute_global_address" "kong-global-address" {
  name = "kong-global-address"
}

resource "google_compute_global_forwarding_rule" "kong-global-forwarding-rule" {
    project               = var.gcp_project
    name                  = "kong-global-forwarding-rule"
    ip_address            = google_compute_global_address.kong-global-address.address
    port_range            = "80"
    target                = google_compute_target_http_proxy.kong-target-proxy.id
}

resource "google_compute_target_http_proxy" "kong-target-proxy" {
    name        = "kong-target-proxy"
    url_map     = google_compute_url_map.kong-url-map-target-proxy.self_link
}

resource "google_compute_url_map" "kong-url-map-target-proxy" {
    name            = "kong-url-map-target-proxy"
    default_service = google_compute_backend_service.kong-backend.self_link

    host_rule {
        hosts        = ["example.com"]
        path_matcher = "allpaths"
    }

    path_matcher {
        name            = "allpaths"
        default_service = google_compute_backend_service.kong-backend.id

        path_rule {
            paths   = ["/"]
            service = google_compute_backend_service.kong-backend.id
        }
    }
}

# ------------------------------------------------------------------------------
# CREATE BACKEND SERVICE
# ------------------------------------------------------------------------------

resource "google_compute_backend_service" "kong-backend" {
    project          = var.gcp_project
    name             = var.lb_name
    protocol         = "HTTP"
    timeout_sec      = 10
    # load_balancing_scheme = "INTERNAL_SELF_MANAGED"
    session_affinity = "NONE"

    dynamic "backend" {
        for_each = local.backends
        content {
            description = lookup(backend.value, "description", null)
            group       = lookup(backend.value, "group", null)
        }
    }

    health_checks = [
        compact(
            concat(
                google_compute_health_check.tcp.*.self_link,
                google_compute_health_check.http.*.self_link
            )
        )[0]
    ]
}

# ------------------------------------------------------------------------------
# CREATE HEALTH CHECK - ONE OF ´http´ OR ´tcp´
# ------------------------------------------------------------------------------

resource "google_compute_health_check" "tcp" {
    count = var.http_health_check ? 0 : 1

    project = var.gcp_project
    name    = format("%s-hc", var.lb_name)

    tcp_health_check {
        port = var.health_check_port
    }
}

resource "google_compute_health_check" "http" {
    count = var.http_health_check ? 1 : 0

    project = var.gcp_project
    name    = format("%s-hc", var.lb_name)

    http_health_check {
        port = var.health_check_port
    }
}

# ------------------------------------------------------------------------------
# CREATE FIREWALLS FOR THE LOAD BALANCER AND HEALTH CHECKS
# ------------------------------------------------------------------------------

# Load balancer firewall allows ingress traffic from instances tagged with any of the ´var.source_tags´
resource "google_compute_firewall" "load_balancer" {
    project = var.gcp_project
    name    = format("%s-ilb-fw", var.lb_name)
    network = var.gcp_network

    allow {
        protocol = lower(var.protocol)
        ports    = var.ports
    }

    # Source tags defines a source of traffic as coming from the primary internal IP address
    # of any instance having a matching network tag.
    source_tags = var.source_tags

    # Target tags define the instances to which the rule applies
    target_tags = var.target_tags
}

# Health check firewall allows ingress tcp traffic from the health check IP addresses
resource "google_compute_firewall" "health_check" {
    project = var.gcp_project
    name    = format("%s-hc", var.lb_name)
    network = var.gcp_network

    allow {
        protocol = "tcp"
        ports    = [var.health_check_port]
    }

    # These IP ranges are required for health checks
    source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

    # Target tags define the instances to which the rule applies
    target_tags = concat(var.target_tags, ["kong-firewall"])
}