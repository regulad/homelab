variable "state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false

  validation {
    condition     = length(var.state_encryption_passphrase) >= 32
    error_message = "Use the generated state passphrase from the encrypted inputs."
  }
}

# tofu/tailscale's own state passphrase, which prepare.sh reads from
# tofu/tailscale/secrets.sops.yaml, to decrypt the outputs tailscale.tf reads.
variable "tailscale_state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false
}

# tofu/azure's own state passphrase, which prepare.sh reads from
# tofu/azure/secrets.sops.yaml, to decrypt the outputs azure.tf reads.
variable "azure_state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false
}

# regulad's personal access tokens, issued by GitHub, each under its name there,
# terraform-<word>--<word>: classic tokens under pat, fine-grained ones under
# fine_grained. prepare.sh reads them from tofu/github-user/personal.sops.yaml,
# their only copy, as tofu/vercel does.
variable "github_pats" {
  type = object({
    pat          = map(string)
    fine_grained = map(string)
  })
  sensitive = true
  nullable  = false
}

# regubot's, likewise, which prepare.sh reads from
# tofu/github-user/bot.sops.yaml, their only copy.
variable "bot_github_pats" {
  type = object({
    pat          = map(string)
    fine_grained = map(string)
  })
  sensitive = true
  nullable  = false
}

# Sentry organization auth tokens, issued by Sentry, each under its name there,
# terraform-<repository>, which prepare.sh reads from
# tofu/sentry/org-tokens.sops.yaml, their only copy.
variable "sentry_auth_tokens" {
  type      = map(string)
  sensitive = true
  nullable  = false
}

# The other values the repositories' workflows use, issued by their services
# or made by hand, by repository.
variable "doppelganger" {
  type = object({
    sops_age_key = string
  })
  sensitive = true
  nullable  = false
}

variable "kodi_plugins" {
  type = object({
    sops_age_key = string
  })
  sensitive = true
  nullable  = false
}

variable "closecircuit" {
  type = object({
    sops_age_key = string
  })
  sensitive = true
  nullable  = false
}

variable "supir" {
  type = object({
    sops_age_key = string
  })
  sensitive = true
  nullable  = false
}

# Nexus users' passwords, by user ID, which prepare.sh reads from
# ansible-generated's nexus_servers.sops.yml, their only copy.
variable "nexus_passwords" {
  type      = map(string)
  sensitive = true
  nullable  = false
}
