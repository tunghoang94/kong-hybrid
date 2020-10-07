terraform {
  # This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
  required_version = ">= 0.12"
}

resource "random_string" "vm-name" {
  length  = 4
}

# KONG CONTROL PLANE
resource "google_compute_instance" "kong-cp" {
    project      = var.gcp_project
    name         = "${var.kong_cp_name}-${var.region}-${random_string.vm-name.result}"
    machine_type = var.machine_type
    zone         = var.zone

    tags = ["kong-cp"]

    boot_disk {
        initialize_params {
            image = var.kong_cp_image
        }
    }

    // Local SSD disk
    scratch_disk {
        interface = "SCSI"
    }

    network_interface {
        network = var.network
        network_ip = var.kong_cp_ip

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

# KONG DATA PLANE
resource "google_compute_instance" "kong-dp" {
    project      = var.gcp_project
    name         = "${var.kong_dp_name}-${var.region}-${random_string.vm-name.result}"
    machine_type = var.machine_type
    zone         = var.zone

    tags = ["kong-dp"]

    boot_disk {
        initialize_params {
            image = var.kong_dp_image
        }
    }

    // Local SSD disk
    scratch_disk {
        interface = "SCSI"
    }

    network_interface {
        network = var.network

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

resource "google_compute_instance_group" "kong-dp-group" {
    project            = var.gcp_project
    name               = "${var.kong_dp_group}-${var.region}"
    zone               = var.zone
    instances          = [google_compute_instance.kong-dp.id]
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
