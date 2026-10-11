resource "azurerm_monitor_activity_log_alert" "service_health_issue_in__honeydrunk_dev_" {
  description         = "Service Health issue alert for oleg@honeydrunkstudios.com\n[AzureApp]-[98c8b5]"
  enabled             = true
  location            = "global"
  name                = "Service Health issue in 'honeydrunk-dev'"
  resource_group_name = "azureapp-auto-alerts-98c8b5-oleg_honeydrunkstudios_com"
  scopes              = ["/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc"]
  tags = {
  }
  action {
    action_group_id = "/subscriptions/82073DA5-BD6D-4874-947E-73B791054CBC/resourceGroups/azureapp-auto-alerts-98c8b5-oleg_honeydrunkstudios_com/providers/microsoft.insights/actionGroups/azureapp-auto"
    webhook_properties = {
    }
  }
  criteria {
    caller                  = null
    category                = "ServiceHealth"
    level                   = null
    levels                  = []
    operation_name          = null
    recommendation_category = null
    recommendation_impact   = null
    recommendation_type     = null
    resource_group          = null
    resource_groups         = []
    resource_id             = null
    resource_ids            = []
    resource_provider       = null
    resource_providers      = []
    resource_type           = null
    resource_types          = []
    status                  = null
    statuses                = []
    sub_status              = null
    sub_statuses            = []
    service_health {
      events    = ["Incident"]
      locations = []
      services  = []
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_monitor_action_group" "azureapp_auto" {
  enabled             = true
  location            = "global"
  name                = "azureapp-auto"
  resource_group_name = "azureapp-auto-alerts-98c8b5-oleg_honeydrunkstudios_com"
  short_name          = "azureapp"
  tags = {
  }
  azure_app_push_receiver {
    email_address = "oleg@honeydrunkstudios.com"
    name          = "Service Health Issues for Azure application"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_monitor_action_group" "application_insights_smart_detection" {
  enabled             = true
  location            = "global"
  name                = "Application Insights Smart Detection"
  resource_group_name = "rg-hd-notify-dev"
  short_name          = "SmartDetect"
  tags = {
  }
  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }
  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
