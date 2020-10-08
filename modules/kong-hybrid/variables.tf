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

variable "zones" {
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

variable "gcp_network" {
  description = "Self link of the VPC network in which to deploy the resources."
  type        = string
}

variable "gcp_subnetwork" {
  description = "Self link of the VPC subnetwork in which to deploy the resources."
  type        = string
  default     = ""
}

variable "protocol" {
  description = "The protocol for the backend and frontend forwarding rule. TCP or UDP."
  type        = string
  default     = "TCP"
}

variable "ip_address" {
  description = "IP address of the load balancer. If empty, an IP address will be automatically assigned."
  type        = string
  default     = ""
}

variable "service_label" {
  description = "An optional prefix to the service name for this Forwarding Rule. If specified, will be the first label of the fully qualified service name."
  type        = string
  default     = ""
}

variable "gcp_network_project" {
  description = "The name of the GCP Project where the network is located. Useful when using networks shared between projects. If empty, var.project will be used."
  type        = string
  default     = ""
}

variable "http_health_check" {
  description = "Set to true if health check is type http, otherwise health check is tcp."
  type        = bool
  default     = false
}

variable "session_affinity" {
  description = "The session affinity for the backends, e.g.: NONE, CLIENT_IP. Default is `NONE`."
  type        = string
  default     = "NONE"
}

variable "source_tags" {
  description = "List of source tags for traffic between the internal load balancer."
  type        = list(string)
  default     = []
}

variable "target_tags" {
  description = "List of target tags for traffic between the internal load balancer."
  type        = list(string)
  default     = []
}

variable "custom_labels" {
  description = "A map of custom labels to apply to the resources. The key is the label name and the value is the label value."
  type        = map(string)
  default     = {}
}