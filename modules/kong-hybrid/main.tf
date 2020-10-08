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

    tags = ["kong-cp", "kong-firewall"]

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

    tags = ["kong-cp", "kong-firewall"]

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

# # KONG DATA PLANE
# resource "google_compute_instance" "kong-dp-region1" {
#     project      = var.gcp_project
#     zone         = var.zones[0]
#     name         = "${var.kong_dp_name}-${var.regions[0]}-${random_string.vm-name.result}"
#     machine_type = var.machine_type

#     tags = ["kong-dp", "kong-firewall-${var.regions[0]}"]

#     boot_disk {
#         initialize_params {
#             image = var.kong_dp_images[0]
#         }
#     }

#     // Local SSD disk
#     scratch_disk {
#         interface = "SCSI"
#     }

#     network_interface {
#         network = var.network

#         access_config {
#             // Ephemeral IP
#         }
#     }

#     scheduling {
#         preemptible = true
#         automatic_restart = false
#         on_host_maintenance = "TERMINATE"
#     }

#     metadata_startup_script = var.kong_startup_script
# }

# resource "google_compute_instance" "kong-dp-region2" {
#     project      = var.gcp_project
#     zone         = var.zones[1]
#     name         = "${var.kong_dp_name}-${var.regions[1]}-${random_string.vm-name.result}"
#     machine_type = var.machine_type

#     tags = ["kong-dp", "kong-firewall-${var.regions[1]}"]

#     boot_disk {
#         initialize_params {
#             image = var.kong_dp_images[1]
#         }
#     }

#     // Local SSD disk
#     scratch_disk {
#         interface = "SCSI"
#     }

#     network_interface {
#         network = var.network

#         access_config {
#             // Ephemeral IP
#         }
#     }

#     scheduling {
#         preemptible = true
#         automatic_restart = false
#         on_host_maintenance = "TERMINATE"
#     }

#     metadata_startup_script = var.kong_startup_script
# }

# resource "google_compute_instance_group" "kong-dp-group-region1" {
#     project            = var.gcp_project
#     name               = "${var.kong_dp_group}-${var.regions[0]}"
#     zone               = var.zones[0]
#     instances          = [google_compute_instance.kong-dp-region1.id]
# }

# resource "google_compute_instance_group" "kong-dp-group-region2" {
#     project            = var.gcp_project
#     name               = "${var.kong_dp_group}-${var.regions[1]}"
#     zone               = var.zones[1]
#     instances          = [google_compute_instance.kong-dp-region2.id]
# }

resource "google_compute_instance_template" "kong-dp-instance-template-region1" {
    name         = "kong-dp-instance-template-region1"
    machine_type = "custom-2-2048"
    region       = var.regions[0]
    tags         = ["kong-firewall"]
    // boot disk
    disk {
        source_image = var.kong_dp_images[0]
    }

    // networking
    network_interface {
        network = "default"
    }

    lifecycle {
        create_before_destroy = true
    }

    metadata_startup_script = var.kong_startup_script
}

resource "google_compute_instance_template" "kong-dp-instance-template-region2" {
    name         = "kong-dp-instance-template-region2"
    machine_type = "custom-2-2048"
    region       = var.regions[1]
    tags         = ["kong-firewall"]
    // boot disk
    disk {
        source_image = var.kong_dp_images[1]
    }

    // networking
    network_interface {
        network = "default"
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
    port         = "8000"
  }
}

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE
# ------------------------------------------------------------------------------

# resource "google_compute_global_forwarding_rule" "default" {
#     project               = var.gcp_project
#     name                  = var.lb_name
#     target                = google_compute_target_http_proxy.default.id
#     port_range            = "80"
# }

# resource "google_compute_global_forwarding_rule" "default" {
#     project               = var.gcp_project
#     name                  = var.lb_name
#     network               = var.gcp_network
#     subnetwork            = var.gcp_subnetwork
#     load_balancing_scheme = "INTERNAL_SELF_MANAGED"
#     backend_service       = google_compute_backend_service.default.self_link
#     ip_protocol           = var.protocol
#     ports                 = var.ports

#     # If service label is specified, it will be the first label of the fully qualified service name.
#     # Due to the provider failing with an empty string, we're setting the name as service label default
#     service_label = var.service_label == "" ? var.lb_name : var.service_label
# }

resource "google_compute_global_forwarding_rule" "default" {
    project               = var.gcp_project
    name                  = "global-rule"
    target                = google_compute_target_http_proxy.default.id
    port_range            = "80"
    load_balancing_scheme = "INTERNAL_SELF_MANAGED"
    ip_address            = "0.0.0.0"
}

resource "google_compute_target_http_proxy" "default" {
    name        = "target-proxy"
    description = "a description"
    url_map     = google_compute_url_map.default.id
}

resource "google_compute_url_map" "default" {
    name            = "url-map-target-proxy"
    description     = "a description"
    default_service = google_compute_backend_service.default.id

    host_rule {
        hosts        = ["example.com"]
        path_matcher = "allpaths"
    }

    path_matcher {
        name            = "allpaths"
        default_service = google_compute_backend_service.default.id

        path_rule {
            paths   = ["/"]
            service = google_compute_backend_service.default.id
        }
    }
}

# ------------------------------------------------------------------------------
# CREATE BACKEND SERVICE
# ------------------------------------------------------------------------------

resource "google_compute_backend_service" "default" {
    project          = var.gcp_project
    name             = var.lb_name
    protocol         = var.protocol
    timeout_sec      = 10
    load_balancing_scheme = "INTERNAL_SELF_MANAGED"
    session_affinity = var.session_affinity

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