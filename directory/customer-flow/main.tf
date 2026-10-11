# Existing flow settings and provider/attribute relationships have separate API ownership.
resource "msgraph_resource" "sign_up_sign_in" {
  api_version = "v1.0"
  body = {
    "@odata.type" = "#microsoft.graph.externalUsersSelfServiceSignUpEventsFlow"
    "displayName" = "HoneyDrunkSignUpSignIn"
    "onInteractiveAuthFlowStart" = {
      "@odata.type"     = "#microsoft.graph.onInteractiveAuthFlowStartExternalUsersSelfServiceSignUp"
      "isSignUpAllowed" = true
    }
    "onUserCreateStart" = {
      "@odata.type"      = "#microsoft.graph.onUserCreateStartExternalUsersSelfServiceSignUp"
      "userTypeToCreate" = "member"
    }
    "onAttributeCollection" = {
      "@odata.type" = "#microsoft.graph.onAttributeCollectionExternalUsersSelfServiceSignUp"
      "attributeCollectionPage" = {
        "views" = [{
          "title"       = null
          "description" = null
          "inputs" = [{
            "attribute"        = "email"
            "label"            = "Email Address"
            "inputType"        = "text"
            "defaultValue"     = null
            "hidden"           = true
            "editable"         = false
            "writeToDirectory" = true
            "required"         = true
            "validationRegEx"  = "^[a-zA-Z0-9.!#$%&amp;&#8217;'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$"
            "options"          = []
            }, {
            "attribute"        = "displayName"
            "label"            = "Display Name"
            "inputType"        = "text"
            "defaultValue"     = null
            "hidden"           = false
            "editable"         = true
            "writeToDirectory" = true
            "required"         = false
            "validationRegEx"  = "^.*"
            "options"          = []
          }]
        }]
      }
    }
  }
  create_method           = null
  create_query_parameters = null
  delete_query_parameters = null
  ignore_missing_property = true
  read_query_parameters   = null
  response_export_values  = null
  retry                   = null
  update_method           = null
  update_query_parameters = null
  url                     = "identity/authenticationEventsFlows"
  lifecycle {
    prevent_destroy = true
  }
}

resource "msgraph_resource" "email_otp" {
  url         = "identity/authenticationEventsFlows/3c679ecf-a488-4759-8011-c86f3cc0f921/microsoft.graph.externalUsersSelfServiceSignUpEventsFlow/onAuthenticationMethodLoadStart/microsoft.graph.onAuthenticationMethodLoadStartExternalUsersSelfServiceSignUp/identityProviders/$ref"
  api_version = "v1.0"
  body = {
    "@odata.id" = "https://graph.microsoft.com/v1.0/identityProviders/EmailOtpSignup-OAUTH"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "msgraph_resource" "email_attribute" {
  url         = "identity/authenticationEventsFlows/3c679ecf-a488-4759-8011-c86f3cc0f921/microsoft.graph.externalUsersSelfServiceSignUpEventsFlow/onAttributeCollection/microsoft.graph.onAttributeCollectionExternalUsersSelfServiceSignUp/attributes/$ref"
  api_version = "v1.0"
  body = {
    "@odata.id" = "https://graph.microsoft.com/v1.0/identity/userFlowAttributes/email"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "msgraph_resource" "display_name_attribute" {
  url         = "identity/authenticationEventsFlows/3c679ecf-a488-4759-8011-c86f3cc0f921/microsoft.graph.externalUsersSelfServiceSignUpEventsFlow/onAttributeCollection/microsoft.graph.onAttributeCollectionExternalUsersSelfServiceSignUp/attributes/$ref"
  api_version = "v1.0"
  body = {
    "@odata.id" = "https://graph.microsoft.com/v1.0/identity/userFlowAttributes/displayName"
  }
  lifecycle {
    prevent_destroy = true
  }
}
