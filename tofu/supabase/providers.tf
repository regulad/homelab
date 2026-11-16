# The homelab-tofu scoped personal access token, limited to the regulad
# organization, comes from provider.sops.env (SUPABASE_ACCESS_TOKEN), which
# sourcing prepare.sh exports.
provider "supabase" {}
