mock_provider "msgraph" {
  mock_data "msgraph_resource" {
    defaults = {
      output = { application_ids = ["92a9912e-3ff7-491a-8f9c-c220bb8d4434"] }
    }
  }
}
run "preserve_existing_contract" {
  command = plan
  assert {
    condition     = msgraph_resource.sign_up_sign_in.body.onInteractiveAuthFlowStart.isSignUpAllowed && endswith(msgraph_resource.email_otp.body["@odata.id"], "/EmailOtpSignup-OAUTH")
    error_message = "Existing email OTP sign-up behavior must be preserved."
  }
}
run "reject_missing_application_binding" {
  command = plan
  override_data {
    target = data.msgraph_resource.application_binding
    values = { output = { application_ids = [] } }
  }
  expect_failures = [data.msgraph_resource.application_binding]
}
