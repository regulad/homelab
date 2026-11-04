# The homelab-tofu service account's key, whose public half alone Google
# holds, comes from provider.sops.yaml: sourcing prepare.sh exports it as
# GOOGLE_CREDENTIALS, and the account's project as GOOGLE_PROJECT.
provider "google" {}
