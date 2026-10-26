# The account's master application key comes from provider.sops.env
# (B2_APPLICATION_KEY_ID and B2_APPLICATION_KEY), which sourcing prepare.sh
# exports.
provider "b2" {}
