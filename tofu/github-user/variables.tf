variable "state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false

  validation {
    condition     = length(var.state_encryption_passphrase) >= 32
    error_message = "Use the generated state passphrase from the encrypted inputs."
  }
}

# The workspace's account token, terraform-github--user, which prepare.sh
# exports as TF_VAR_github_token.
variable "github_token" {
  type      = string
  sensitive = true
  nullable  = false
}
