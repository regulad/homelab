# Each workspace is one of the account's modes, live or sandbox, and the
# provider takes that mode's key, so a key never meets the other mode's state.
# sandbox is precisely what Stripe calls the account's Test mode, not one of
# its Sandboxes. The default workspace has no key, and a plan there fails.
provider "stripe" {
  api_key = var.api_keys[terraform.workspace]
}
