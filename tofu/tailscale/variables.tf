variable "state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false

  validation {
    condition     = length(var.state_encryption_passphrase) >= 32
    error_message = "Use the generated state passphrase from the encrypted inputs."
  }
}

# tofu/oracle's own state passphrase, which prepare.sh reads from
# tofu/oracle/secrets.sops.json, to decrypt the outputs oracle.tf reads.
variable "oracle_state_encryption_passphrase" {
  type      = string
  sensitive = true
  nullable  = false
}
