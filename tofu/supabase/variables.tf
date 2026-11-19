# The doppelganger project's database password, the postgres role's, from
# secrets.sops.yaml. Supabase never returns it, so it lives only there.
variable "database_password" {
  type      = string
  sensitive = true
  nullable  = false

  validation {
    condition     = length(var.database_password) >= 32
    error_message = "Use the generated database password from the encrypted inputs."
  }
}

# Google's OAuth client secrets, by project, then by slug, which prepare.sh
# reads from tofu/gcp/oauth-clients.sops.json, their only copy. The API returns
# only their hashes, so the provider keeps them from state.
variable "google_oauth_client_secrets" {
  type      = map(map(string))
  sensitive = true
  nullable  = false
}
