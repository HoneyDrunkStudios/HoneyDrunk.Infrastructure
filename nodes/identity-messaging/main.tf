locals {
  tags = {
    "hd:node"        = "honeydrunk-identity"
    "hd:env"         = var.environment
    "hd:owner"       = "honeydrunkstudios"
    "hd:cost-center" = "identity"
    "hd:dr-tier"     = "T2"
    "hd:adr"         = "ADR-0077"
  }
  platform_group = "rg-hd-platform-${var.environment}"
}

module "queues" {
  for_each     = toset(["identity-lifecycle-acks", "pocketquests-lifecycle"])
  source       = "../../modules/messaging/queue"
  name         = each.value
  namespace_id = var.namespace_id
}
