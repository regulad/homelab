# The homelab-tofu service account's key, whose public half alone Google
# holds, comes from provider.sops.yaml: sourcing prepare.sh exports it as
# GOOGLE_CREDENTIALS, and the account's project as GOOGLE_PROJECT.
provider "google" {}

# Calls billed to home-assistant-311214 rather than to the account's own
# project, regulad, which hasn't enabled the Firebase APIs: home-assistant-311214
# has, so its Firebase resources, which only google-beta has, use this.
provider "google-beta" {
  alias                 = "home_assistant"
  user_project_override = true
  billing_project       = "home-assistant-311214"
}
