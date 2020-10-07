locals {
    project             = var.gcp_project
    
    # kong conf
    kong_cp_name            = "kong-cp"
    kong_cp_image_taiwan    = "kong-cp-taiwan-1602062265"
    kong_cp_image_singapore = "kong-cp-singapore-1602062491"
    kong_cp_ip_taiwan       = "10.140.0.50"
    kong_cp_ip_singapore    = "10.148.0.50"

    kong_dp_name            = "kong-dp"
    kong_dp_image_taiwan    = "kong-dp-taiwan-1602062757"
    kong_dp_image_singapore = "kong-dp-singapore-1602062987"
    kong_dp_group           = "kong-dp"
    
    kong_startup_script    = file("scripts/startup_kong_hybrid.sh")

    region_taiwan       = "taiwan"
    region_singapore    = "singapore"
    zone_taiwan         = "asia-east1-a"
    zone_singapore      = "asia-southeast1-a"
    
    # lb 
    lb_name             = "kong-internal-lb"
    region              = "asia-east1"
    network             = "default"
    port                = 80
    http_health_check   = false
    custom_labels       = ["ilb"]
}

module "kong-hybrid-taiwan" {
    source          = "./modules/kong-hybrid"
    
    gcp_project     = local.project
    region          = local.region_taiwan
    zone            = local.zone_taiwan
    
    kong_dp_name    = local.kong_dp_name
    kong_dp_image   = local.kong_dp_image_taiwan
    kong_dp_group   = local.kong_dp_group

    kong_cp_name    = local.kong_cp_name
    kong_cp_image   = local.kong_cp_image_taiwan
    kong_cp_ip      = local.kong_cp_ip_taiwan

    kong_startup_script = local.kong_startup_script
    network             = local.network
}

module "internal-lb" {
    source  = "./modules/tf-internal-lb-gcp"
    name    = local.lb_name
    gcp_region  = local.region
    gcp_project = local.project
    
    backends = [
        {
            description = "Instance group for internal-load-balancer"
            group       = google_compute_instance_group.kong-dp-group.*.self_link
        },
        # {
        #     description = "Instance group for internal-load-balancer"
        #     group       = google_compute_instance_group.kong-dp-group-hongkong.self_link
        # }
    ]

    # This setting will enable internal DNS for the load balancer
    service_label          = local.lb_name
    gcp_network            = local.network

    health_check_port      = local.port
    http_health_check      = local.http_health_check
    target_tags            = [local.lb_name]
    source_tags            = [local.lb_name]
    ports                  = [local.port]
}