# The homelab-tofu restricted key of each of the account's modes, keyed by
# workspace, from secrets.sops.yaml: sandbox's is Stripe's Test mode key.
variable "api_keys" {
  type = object({
    live    = string
    sandbox = string
  })
  sensitive = true
  nullable  = false

  validation {
    condition     = startswith(var.api_keys.live, "rk_live_") && startswith(var.api_keys.sandbox, "rk_test_")
    error_message = "api_keys.live must be a live restricted key (rk_live_), and api_keys.sandbox a sandbox one (rk_test_)."
  }
}
