# Preserve the existing development public certificate. Its payload/encoding cannot
# be reconstructed by the importer; ignore those write-only fields, not key ID/dates.
# Private key material is never present. Credential rotation is a separate operation.
resource "azuread_service_principal_delegated_permission_grant" "existing_0" {
  claim_values                         = ["User.Read"]
  resource_service_principal_object_id = "e2d0c9b8-e8e8-4732-9190-aa49bdf68fd3"
  service_principal_object_id          = "8c1a4398-19e1-46e5-a951-971154567271"
  user_object_id                       = null
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal_delegated_permission_grant" "existing_2" {
  claim_values                         = ["access_as_user"]
  resource_service_principal_object_id = "8c1a4398-19e1-46e5-a951-971154567271"
  service_principal_object_id          = "4177498d-ea98-4cfe-8927-ad3a6acea8c8"
  user_object_id                       = null
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_service_principal_delegated_permission_grant" "existing_1" {
  claim_values                         = ["User.Read"]
  resource_service_principal_object_id = "e2d0c9b8-e8e8-4732-9190-aa49bdf68fd3"
  service_principal_object_id          = "4177498d-ea98-4cfe-8927-ad3a6acea8c8"
  user_object_id                       = null
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_app_role_assignment" "identity_api_0" {
  app_role_id         = "df021288-bdef-4463-88db-98f22de89214"
  principal_object_id = "8c1a4398-19e1-46e5-a951-971154567271"
  resource_object_id  = "e2d0c9b8-e8e8-4732-9190-aa49bdf68fd3"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azuread_application_certificate" "identity_api" {
  application_id = "/applications/91fae05b-d1fa-42d6-acfe-5b13c4c7856f"
  encoding       = "base64"
  end_date       = "2026-12-27T23:09:39Z"
  key_id         = "b025772c-4bca-4e51-8d06-3b10884a40ab"
  start_date     = "2026-09-28T22:59:39Z"
  type           = "AsymmetricX509Cert"
  value          = "MIIDKjCCAhKgAwIBAgIQWjE9Ed6zp5tK5YoR5j0DLjANBgkqhkiG9w0BAQsFADAoMSYwJAYDVQQDDB1Ib25leURydW5rIElkZW50aXR5IERldiBHcmFwaDAeFw0yNjA5MjgyMjU5MzlaFw0yNjEyMjcyMzA5MzlaMCgxJjAkBgNVBAMMHUhvbmV5RHJ1bmsgSWRlbnRpdHkgRGV2IEdyYXBoMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxzyzBr7I+gVB8kmr55R7UDWDqvPgTL9MkEZ3UHJ5LqJAeX3Kz8900SGvNAdwpPDjeKpbIY2EZPmmZASs5yDM0tYa/Vn/hPLUNGFZgUXdXJAqaZvfjqhzgaT1HxarYbfQ6QpDp0wQm/EZwpxT1R+FzkOsgMUd8ONE8lDpFIRNIgoEnwfM7ZUg7q3yY/tT3IJOUDBylNg7QOKQ0v32ofmG/Ifeg90CZzLC0PtijlTq0jV5FMZ9bjg+Jy+UTgOWM1oOc5wOr86sPTifCB6mKCLuMv2lr83yO5cma7jIqaOaBJiiyfIyyDnFzsENCBSHLex1S8fnhtWAWWMWRv/lWG4okQIDAQABo1AwTjAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMB0GA1UdDgQWBBTkHS1ffUZgwIU+bcmoZL7SgzhLdzANBgkqhkiG9w0BAQsFAAOCAQEAL5sTEQy/xSzhzttuDewyZZHkOw3i5TItec9Lkf068km5F5vrWeMJvQMcrXDIFtXEirM7+wsruWXAGbEFXrcsEewiWDOJGIWpWjrqv8TXdYGATZ304dPuMZTi2sjFeojtF2H9CXJ8m7xT4eagoWxPnyHEvoyQyNhvdzScjTZtAPiqGc+Uj4o2HqWRrOqOniBJ0JvtCTV/e3JwsPEhZ+rWicfANepKaKHD6UYtDqCeytX6RWHyQ00vN4aMV5v1Q7MJXncjG6EA4Hn5Eq5KC9J3RDa4o67do7mflZaPLY7xqOeHCk+dTre8CO+BICg1nG8BuYwgfdtHDS7jwXxBozJDxA=="
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [value, encoding]
  }
}

resource "azuread_service_principal" "identity_api" {
  account_enabled               = true
  alternative_names             = []
  app_role_assignment_required  = false
  client_id                     = "28e2b75a-6a53-44f9-88d9-02df60549974"
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

resource "azuread_service_principal" "pocket_quests_web" {
  account_enabled               = true
  alternative_names             = []
  app_role_assignment_required  = false
  client_id                     = "92a9912e-3ff7-491a-8f9c-c220bb8d4434"
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

resource "azuread_application" "pocket_quests_web" {
  description                    = null
  device_only_auth_enabled       = false
  display_name                   = "Pocket Quests Web - Dev"
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
    requested_access_token_version = 2
  }
  public_client {
    redirect_uris = []
  }
  required_resource_access {
    resource_app_id = "28e2b75a-6a53-44f9-88d9-02df60549974"
    resource_access {
      id   = "092c8a8d-81d7-4f71-bce3-8b8c954e3069"
      type = "Scope"
    }
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
  single_page_application {
    redirect_uris = ["http://localhost:8081/callback"]
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

resource "azuread_application" "identity_api" {
  description                    = null
  device_only_auth_enabled       = false
  display_name                   = "HoneyDrunk Identity API - Dev"
  fallback_public_client_enabled = false
  group_membership_claims        = []
  identifier_uris                = ["api://28e2b75a-6a53-44f9-88d9-02df60549974"]
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
    requested_access_token_version = 2
    oauth2_permission_scope {
      admin_consent_description  = "Allows the application to access HoneyDrunk Identity on behalf of the signed-in user."
      admin_consent_display_name = "Access HoneyDrunk Identity"
      enabled                    = true
      id                         = "092c8a8d-81d7-4f71-bce3-8b8c954e3069"
      type                       = "Admin"
      user_consent_description   = null
      user_consent_display_name  = null
      value                      = "access_as_user"
    }
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
    resource_access {
      id   = "df021288-bdef-4463-88db-98f22de89214"
      type = "Role"
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
