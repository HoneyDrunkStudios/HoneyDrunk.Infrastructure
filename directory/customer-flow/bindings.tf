# Graph exposes this association through list/add/remove operations but has no
# usable item GET for the pinned generic provider. Do not fake resource ownership
# or re-add an existing association. Fail planning if its exact membership drifts.
data "msgraph_resource" "application_binding" {
  url         = "identity/authenticationEventsFlows/3c679ecf-a488-4759-8011-c86f3cc0f921/conditions/applications/includeApplications"
  api_version = "v1.0"
  response_export_values = {
    application_ids = "value[].appId"
  }
  lifecycle {
    postcondition {
      condition     = toset(self.output.application_ids) == toset(["92a9912e-3ff7-491a-8f9c-c220bb8d4434"])
      error_message = "The Pocket Quests sign-up flow binding changed. Stop and review the Graph association API; do not recreate the flow."
    }
  }
}
