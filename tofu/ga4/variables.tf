# tofu-analytics's private key (providers.tf), PEM, from provider.sops.yaml,
# its only copy, which sourcing prepare.sh exports as TF_VAR_private_key, so
# that it stays in the environment, never on disk.
variable "private_key" {
  type      = string
  sensitive = true
  nullable  = false
}
