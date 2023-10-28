terraform {
  required_version = "~> 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.77.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.common.prefix}-${var.common.env}-rg"
  location = var.common.location
}

resource "azurerm_container_registry" "acr" {
  name                          = "${var.common.prefix}${var.common.env}acr"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  sku                           = var.container_registry.sku_name
  admin_enabled                 = true
  public_network_access_enabled = var.container_registry.public_network_access_enabled
  zone_redundancy_enabled       = var.container_registry.zone_redundancy_enabled
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.common.prefix}-${var.common.env}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = var.app_service_plan.os_type
  sku_name            = var.app_service_plan.sku_name
}

resource "azurerm_linux_web_app" "webapp" {
  name                          = "${var.common.prefix}-${var.common.env}-webapp"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  service_plan_id               = azurerm_service_plan.plan.id
  https_only                    = var.app_service.https_only
  public_network_access_enabled = var.app_service.public_network_access_enabled

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = azurerm_container_registry.acr.login_server
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
  }

  site_config {
    always_on                   = var.app_service.site_config.always_on
    ftps_state                  = var.app_service.site_config.ftps_state
    vnet_route_all_enabled      = var.app_service.site_config.vnet_route_all_enabled
    scm_use_main_ip_restriction = false

    application_stack {
      # Initial container image (overwritten by CI/CD)
      docker_registry_url = "https://mcr.microsoft.com"
      docker_image_name   = "appsvc/staticsite:latest"
    }
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_name,
      site_config[0].application_stack[0].docker_registry_url
    ]
  }
}

# resource "azapi_resource" "app_settings" {
#   type      = "Microsoft.Web/sites/config@2022-03-01"
#   name      = "web"
#   parent_id = azurerm_linux_web_app.webapp.id
#   body = jsonencode({
#     properties = {
#       appSettings = [
#         {
#           name  = "DOCKER_REGISTRY_SERVER_URL"
#           value = azurerm_container_registry.acr.login_server
#         }
#       ]
#     }
#   })
# }
