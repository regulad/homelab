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
# their names on GitHub, classic under pat and fine-grained under fine_grained,
# which prepare.sh reads from tofu/github-user/personal.sops.yaml, their only
# copy.
variable "github_pats" {
  type = object({
    pat          = map(string)
    fine_grained = map(string)
  })
  sensitive = true
  nullable  = false
}
