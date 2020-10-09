locals {
    project             = var.gcp_project
    
    # kong conf
    kong_cp_name            = "kong-cp"
    kong_cp_image_taiwan    = "kong-cp-taiwan-1602210853"
    kong_cp_image_singapore = "kong-cp-singapore-1602211484"
    kong_cp_ip_taiwan       = "10.140.0.50"
    kong_cp_ip_singapore    = "10.148.0.50"

    kong_dp_name            = "kong-dp"
    kong_dp_image_taiwan    = "kong-dp-taiwan-1602211738"
    kong_dp_image_singapore = "kong-dp-singapore-1602211993"
    kong_dp_group           = "kong-dp"
    
    kong_startup_script    = file("scripts/startup_kong_hybrid.sh")

    region_taiwan       = "asia-east1"
    region_singapore    = "asia-southeast1"
    zone_taiwan         = "asia-east1-a"
    zone_singapore      = "asia-southeast1-a"
    
    # lb 
    lb_name             = "kong-internal-lb"
    region              = "asia-east1"
    network             = "default"
    port                = 80
    http_health_check   = false
    custom_labels       = ["ilb"]

    # admin
    kong_admin_image           = "kong-admin-1602218329"
    kong_admin_startup_script  = file("scripts/startup_kong_admin.sh")
}

module "kong-hybrid" {
    source          = "./modules/kong-hybrid"
    
    gcp_project     = local.project
    regions         = [local.region_taiwan, local.region_singapore]
    zones           = [local.zone_taiwan, local.zone_singapore]

    kong_dp_name    = local.kong_dp_name
    kong_dp_images  = [local.kong_dp_image_taiwan, local.kong_dp_image_taiwan] 
    kong_dp_group   = local.kong_dp_group

    kong_cp_name    = local.kong_cp_name
    kong_cp_images  = [local.kong_cp_image_taiwan, local.kong_cp_image_singapore]
    kong_cp_ips     = [local.kong_cp_ip_taiwan, local.kong_cp_ip_singapore]

    kong_startup_script = local.kong_startup_script
    network             = local.network

    lb_name                = local.lb_name
    service_label          = local.lb_name
    gcp_network            = local.network
    health_check_port      = local.port
    http_health_check      = local.http_health_check
    target_tags            = [local.lb_name]
    source_tags            = [local.lb_name]
    ports                  = [local.port]

    kong_admin_image           = local.kong_admin_image
    kong_admin_startup_script  = local.kong_admin_startup_script
}
