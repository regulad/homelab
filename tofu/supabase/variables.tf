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
