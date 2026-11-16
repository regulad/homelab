# The token of homelab-tofu, an internal integration in the regulad
# organization, comes from provider.sops.env (SENTRY_AUTH_TOKEN), which sourcing
# prepare.sh exports. It belongs to the organization, not to a user, so it
# reaches regulad alone and cannot manage members.
provider "sentry" {}
