# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "gcp_project" {
    description = "The project ID to create the resources in."
    type        = string
}

variable "regions" {
    description = "Region"
    type        = list(string)
}

variable "kong_dp_name" {
    description = "Kong data plane name."
    type        = string
}

variable "kong_dp_images" {
    description = "Kong data plane image built by packer."
    type        = list(string)
}

variable "kong_dp_group" {
    description = "Kong data plane group."
    type        = string
}

variable "kong_cp_name" {
    description = "Kong control plane name."
    type        = string
}

variable "kong_cp_images" {
    description = "Kong control plane image built by packer."
    type        = list(string)
}

variable "kong_cp_ips" {
    description = "Kong control plane network ips."
    type        = list(string)
}

variable "kong_startup_script" {
    description = "Kong hybrid startup script url."
    type        = string
}

variable "network" {
    description = "Network."
    type        = string
}

variable "lb_name" {
  description = "Name for the load balancer forwarding rule and prefix for supporting resources."
  type        = string
}

variable "ports" {
  description = "List of ports (or port ranges) to forward to backend services. Max is 5."
  type        = list(string)
}

variable "health_check_port" {
  description = "Port to perform health checks on."
  type        = number
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "machine_type" {
  description = "Machine type."
  type        = string
  default     = "custom-2-2048"
}

variable "root_volume_disk_size_gb" {
  description = "The size, in GB, of the root disk volume on each Consul node."
  type        = number
  default     = 10
}

variable "root_volume_disk_type" {
  description = "The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard."
  type        = string
  default     = "pd-standard"
}