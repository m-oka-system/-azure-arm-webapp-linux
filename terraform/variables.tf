variable "common" {
  type = map(string)
  default = {
    prefix   = "terraform"
    env      = "dev"
    location = "japaneast"
  }
}

variable "container_registry" {
  type = object({
    sku_name                      = string
    admin_enabled                 = bool
    public_network_access_enabled = bool
    zone_redundancy_enabled       = bool
  })
  default = {
    sku_name                      = "Basic"
    admin_enabled                 = false
    public_network_access_enabled = true
    zone_redundancy_enabled       = false
  }
}

variable "app_service_plan" {
  type = map(string)
  default = {
    os_type  = "Linux"
    sku_name = "B1"
  }
}

variable "app_service" {
  type = object({
    https_only                    = bool
    public_network_access_enabled = bool
    site_config = object({
      always_on              = bool
      ftps_state             = string
      vnet_route_all_enabled = bool
    })
  })
  default = {
    https_only                    = true
    public_network_access_enabled = true
    site_config = {
      always_on              = false
      ftps_state             = "Disabled"
      vnet_route_all_enabled = true
    }
  }
}
