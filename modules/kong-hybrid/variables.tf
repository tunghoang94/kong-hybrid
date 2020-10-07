# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "gcp_project" {
    description = "The project ID to create the resources in."
    type        = string
}

variable "region" {
    description = "Region"
    type        = string
}

variable "zone" {
    description = "Zone."
    type        = string
}

variable "kong_dp_name" {
    description = "Kong data plane name."
    type        = string
}

variable "kong_dp_image" {
    description = "Kong data plane image built by packer."
    type        = string
}

variable "kong_dp_group" {
    description = "Kong data plane group."
    type        = string
}

variable "kong_cp_name" {
    description = "Kong control plane name."
    type        = string
}

variable "kong_cp_image" {
    description = "Kong control plane image built by packer."
    type        = string
}

variable "kong_cp_ip" {
    description = "Kong control plane network ip."
    type        = string
}

variable "kong_startup_script" {
    description = "Kong hybrid startup script url."
    type        = string
}

variable "network" {
    description = "Network."
    type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# These variables have defaults, but may be overridden by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "machine_type" {
  description = "Machine type."
  type        = string
  default     = ""
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