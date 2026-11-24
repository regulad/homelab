variable "state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false

  validation {
    condition     = length(var.state_encryption_passphrase) >= 32
    error_message = "Use the generated state passphrase from the encrypted inputs."
  }
}

# The GitHub personal access tokens projects' environments take, under
# their names on GitHub, which prepare.sh reads from
# tofu/github-personal/secrets.sops.yaml, their only copy.
variable "github_pats" {
  type      = map(string)
  sensitive = true
  nullable  = false
}
