resource "azuread_application" "honeydrunk_infrastructure_deploy" {
  description                    = null
  device_only_auth_enabled       = false
  display_name                   = "honeydrunk-infrastructure-deploy"
  fallback_public_client_enabled = false
  group_membership_claims        = []
  identifier_uris                = []
  logo_image                     = null
  marketing_url                  = null
  notes                          = null
  oauth2_post_response_required  = false
  owners                         = []
  prevent_duplicate_names        = false
  privacy_statement_url          = null
  service_management_reference   = null
  sign_in_audience               = "AzureADMyOrg"
  support_url                    = null
  tags                           = []
  terms_of_service_url           = null
  api {
    known_client_applications      = []
    mapped_claims_enabled          = false
    requested_access_token_version = 1
  }
  public_client {
    redirect_uris = []
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
  single_page_application {
    redirect_uris = []
  }
  web {
    homepage_url  = null
    logout_url    = null
    redirect_uris = []
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_application" "sp_hd_pulse_dev" {
  description                    = null
  device_only_auth_enabled       = false
  display_name                   = "sp-hd-pulse-dev"
  fallback_public_client_enabled = false
  group_membership_claims        = []
  identifier_uris                = []
  logo_image                     = null
  marketing_url                  = null
  notes                          = null
  oauth2_post_response_required  = false
  owners                         = []
  prevent_duplicate_names        = false
  privacy_statement_url          = null
  service_management_reference   = null
  sign_in_audience               = "AzureADMyOrg"
  support_url                    = null
  tags                           = []
  terms_of_service_url           = null
  api {
    known_client_applications      = []
    mapped_claims_enabled          = false
    requested_access_token_version = 1
  }
  public_client {
    redirect_uris = []
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
  single_page_application {
    redirect_uris = []
  }
  web {
    homepage_url  = null
    logout_url    = null
    redirect_uris = []
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_application" "sp_hd_notify_dev" {
  description                    = null
  device_only_auth_enabled       = false
  display_name                   = "sp-hd-notify-dev"
  fallback_public_client_enabled = false
  group_membership_claims        = []
  identifier_uris                = []
  logo_image                     = null
  marketing_url                  = null
  notes                          = null
  oauth2_post_response_required  = false
  owners                         = []
  prevent_duplicate_names        = false
  privacy_statement_url          = null
  service_management_reference   = null
  sign_in_audience               = "AzureADMyOrg"
  support_url                    = null
  tags                           = []
  terms_of_service_url           = null
  api {
    known_client_applications      = []
    mapped_claims_enabled          = false
    requested_access_token_version = 1
  }
  public_client {
    redirect_uris = []
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
  single_page_application {
    redirect_uris = []
  }
  web {
    homepage_url  = null
    logout_url    = null
    redirect_uris = []
    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal" "sp_hd_pulse_dev" {
  account_enabled               = true
  alternative_names             = []
  app_role_assignment_required  = false
  client_id                     = "63be5f2c-27f2-4bec-adc1-0d44f9416c1f"
  description                   = null
  login_url                     = null
  notes                         = null
  notification_email_addresses  = []
  owners                        = []
  preferred_single_sign_on_mode = null
  tags                          = ["HideApp", "WindowsAzureActiveDirectoryIntegratedApp"]
  use_existing                  = null
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal" "honeydrunk_infrastructure_deploy" {
  account_enabled               = true
  alternative_names             = []
  app_role_assignment_required  = false
  client_id                     = "0fce147d-3c2a-408d-b122-34af727dddba"
  description                   = null
  login_url                     = null
  notes                         = null
  notification_email_addresses  = []
  owners                        = []
  preferred_single_sign_on_mode = null
  tags                          = ["HideApp", "WindowsAzureActiveDirectoryIntegratedApp"]
  use_existing                  = null
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal" "sp_hd_notify_dev" {
  account_enabled               = true
  alternative_names             = []
  app_role_assignment_required  = false
  client_id                     = "4ca8136a-9fe6-4470-be4f-2a670a5ce6d5"
  description                   = null
  login_url                     = null
  notes                         = null
  notification_email_addresses  = []
  owners                        = []
  preferred_single_sign_on_mode = null
  tags                          = ["HideApp", "WindowsAzureActiveDirectoryIntegratedApp"]
  use_existing                  = null
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_application_federated_identity_credential" "github_pulse_dev" {
  application_id = "/applications/5c895f72-df6c-4341-b7f3-ff7247f0db3a"
  audiences      = ["api://AzureADTokenExchange"]
  description    = null
  display_name   = "github-pulse-dev"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:HoneyDrunkStudios/HoneyDrunk.Pulse:environment:dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_application_federated_identity_credential" "github_notify_dev" {
  application_id = "/applications/b0b59767-e215-4c8c-8b8f-d20a687b2204"
  audiences      = ["api://AzureADTokenExchange"]
  description    = null
  display_name   = "github-notify-dev"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:HoneyDrunkStudios/HoneyDrunk.Notify:environment:dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_application_federated_identity_credential" "gh_infra_main" {
  application_id = "/applications/ef7eafca-d048-47d2-bbeb-ba729f6c1b72"
  audiences      = ["api://AzureADTokenExchange"]
  description    = null
  display_name   = "gh-infra-main"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:HoneyDrunkStudios/HoneyDrunk.Infrastructure:ref:refs/heads/main"
  lifecycle {
    prevent_destroy = true
  }
}
