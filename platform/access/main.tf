resource "azurerm_role_assignment" "existing_daa14232_e321_59ef_8c12_8c9b42e3b2f4" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "daa14232-e321-59ef-8c12-8c9b42e3b2f4"
  principal_id                           = "57316bf5-7b5b-4f5c-b03c-d7c44b10a421"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-pulse-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_8ea0ac7b_13dc_4963_a60c_9504057974c2" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "8ea0ac7b-13dc-4963-a60c-9504057974c2"
  principal_id                           = "a3c7955b-742a-47ba-8e2e-0091c6d1cbfe"
  principal_type                         = "User"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_dcaaa7d5_cbd9_44f1_b924_2760523d20f9" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "dcaaa7d5-cbd9-44f1-b924-2760523d20f9"
  principal_id                           = "a3c7955b-742a-47ba-8e2e-0091c6d1cbfe"
  principal_type                         = "User"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.AppConfiguration/configurationStores/appcs-hd-shared-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_7ae8cf35_50f9_4086_8bc9_dfd4ccbefa0f" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "7ae8cf35-50f9-4086-8bc9-dfd4ccbefa0f"
  principal_id                           = "9a5c16db-74ee-4cea-882e-b1c415cc020e"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ContainerRegistry/registries/acrhdshareddev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_b888279e_bf35_4082_8be2_f02bae1bd852" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "b888279e-bf35-4082-8be2-f02bae1bd852"
  principal_id                           = "346ac7f2-0ae5-4c7f-bd1e-b9a0dc2c9596"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ContainerRegistry/registries/acrhdshareddev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_0bdf19da_8c99_457e_ae09_5d530ff5cebc" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "0bdf19da-8c99-457e-ae09-5d530ff5cebc"
  principal_id                           = "9745a886-40ab-4cd4-be23-1679ffd3c37a"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-pulse-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_d1d6e17c_0d08_4597_93b8_5020371e040b" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "d1d6e17c-0d08-4597-93b8-5020371e040b"
  principal_id                           = "22bee2a0-549b-422c-aa9b-f842193f1c45"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/8142912a-a196-46c5-ade9-b7e96992db38"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.App/managedEnvironments/cae-hd-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_aa364fe7_ecc7_4a18_a162_939ba9fa7c1e" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "aa364fe7-ecc7-4a18-a162-939ba9fa7c1e"
  principal_id                           = "a3c7955b-742a-47ba-8e2e-0091c6d1cbfe"
  principal_type                         = "User"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.KeyVault/vaults/kv-hd-notify-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_c5431da6_2f5d_59cd_97c3_cd4ac34850bb" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "c5431da6-2f5d-59cd-97c3-cd4ac34850bb"
  principal_id                           = "57316bf5-7b5b-4f5c-b03c-d7c44b10a421"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_a12b9647_36a2_4ae3_9254_d10f7e4edd01" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "a12b9647-36a2-4ae3-9254-d10f7e4edd01"
  principal_id                           = "f97a2aee-8b72-4842-b8aa-921c1a53c8d3"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/516239f1-63e1-4d78-a4de-a74fb236a071"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.AppConfiguration/configurationStores/appcs-hd-shared-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_740b8702_6cc4_4374_8102_521dff83995b" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "740b8702-6cc4-4374-8102-521dff83995b"
  principal_id                           = "a3c7955b-742a-47ba-8e2e-0091c6d1cbfe"
  principal_type                         = "User"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-pulse-dev/providers/Microsoft.KeyVault/vaults/kv-hd-pulse-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_cd672e65_435e_4de8_91fd_5a2e2008cbfc" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "cd672e65-435e-4de8-91fd-5a2e2008cbfc"
  principal_id                           = "346ac7f2-0ae5-4c7f-bd1e-b9a0dc2c9596"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.KeyVault/vaults/kv-hd-notify-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_ece6d329_0f3d_4be5_9476_8aee7e136265" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "ece6d329-0f3d-4be5-9476-8aee7e136265"
  principal_id                           = "9a5c16db-74ee-4cea-882e-b1c415cc020e"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_36df29fd_521f_4646_b8c4_980e8a55b6c5" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "36df29fd-521f-4646-b8c4-980e8a55b6c5"
  principal_id                           = "22bee2a0-549b-422c-aa9b-f842193f1c45"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-pulse-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_cc7d73dc_7946_4b0e_8500_a5e80849ea38" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "cc7d73dc-7946-4b0e-8500-a5e80849ea38"
  principal_id                           = "f97a2aee-8b72-4842-b8aa-921c1a53c8d3"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.KeyVault/vaults/kv-hd-notify-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_cb188003_d016_4ce0_8bf7_33dd60100521" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "cb188003-d016-4ce0-8bf7-33dd60100521"
  principal_id                           = "9745a886-40ab-4cd4-be23-1679ffd3c37a"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_9599519b_2be7_400e_b5a4_53a1d054fe5a" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "9599519b-2be7-400e-b5a4-53a1d054fe5a"
  principal_id                           = "22bee2a0-549b-422c-aa9b-f842193f1c45"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/8311e382-0749-4cb8-b61a-304f252e45ec"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev/providers/Microsoft.ContainerRegistry/registries/acrhdshareddev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_30571d18_b96c_474c_8dec_7e874db2bf60" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "30571d18-b96c-474c-8dec-7e874db2bf60"
  principal_id                           = "a3c7955b-742a-47ba-8e2e-0091c6d1cbfe"
  principal_type                         = "User"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b86a8fe4-44ce-4948-aee5-eccb2c155cd7"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-automation-dev/providers/Microsoft.KeyVault/vaults/kv-hd-automation-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_fedc1872_0084_441d_89c1_674a2cc693c0" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "fedc1872-0084-441d-89c1-674a2cc693c0"
  principal_id                           = "9745a886-40ab-4cd4-be23-1679ffd3c37a"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_976da56b_f471_43f1_ad0c_dfee02fb2428" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "976da56b-f471-43f1-ad0c-dfee02fb2428"
  principal_id                           = "9745a886-40ab-4cd4-be23-1679ffd3c37a"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-pulse-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_3f6a78d4_b6a3_52c0_affc_72244368b21a" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "3f6a78d4-b6a3-52c0-affc-72244368b21a"
  principal_id                           = "57316bf5-7b5b-4f5c-b03c-d7c44b10a421"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/516239f1-63e1-4d78-a4de-a74fb236a071"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "existing_82dcb37c_9340_4c09_ba0d_7df97f12b08e" {
  condition                              = null
  delegated_managed_identity_resource_id = null
  description                            = null
  name                                   = "82dcb37c-9340-4c09-ba0d-7df97f12b08e"
  principal_id                           = "9a5c16db-74ee-4cea-882e-b1c415cc020e"
  principal_type                         = "ServicePrincipal"
  role_definition_id                     = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6"
  scope                                  = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-notify-dev/providers/Microsoft.KeyVault/vaults/kv-hd-notify-dev"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_definition" "honeydrunk_pulse_dev_environment_join" {
  assignable_scopes  = ["/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev"]
  description        = "Permit the existing Pulse development deployment identity to join the existing development Container Apps environment. Assign only at cae-hd-dev resource scope."
  name               = "HoneyDrunk Pulse Dev Environment Join"
  role_definition_id = "8142912a-a196-46c5-ade9-b7e96992db38"
  scope              = "/subscriptions/82073da5-bd6d-4874-947e-73b791054cbc/resourceGroups/rg-hd-platform-dev"
  permissions {
    actions          = ["Microsoft.App/managedEnvironments/join/action"]
    data_actions     = []
    not_actions      = []
    not_data_actions = []
  }
  lifecycle {
    prevent_destroy = true
  }
}
