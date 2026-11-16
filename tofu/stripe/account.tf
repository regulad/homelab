# account: the account regulad.xyz (acct_1Th8iPBuafhImQpy), its publishable
# keys, one per mode, by workspace. A publishable key is public by design:
# browsers load Stripe.js with it. Stripe makes and rolls them in the
# Dashboard, and no API returns them.
locals {
  publishable_keys = {
    live    = "pk_live_51Th8iPBuafhImQpy6UbjnO0fsCPdO6YYIm8IZxctp9M2kN9sZGT0qMbqnS6QZEpWUoFnRxZ9eZrcYYDHU5BiMFkH00y5sIp6la"
    sandbox = "pk_test_51Th8iPBuafhImQpydeicsgICWUsOjGzR4OcbtXsmatTGPYu8Y4rdxEiKPx0cj081IqneNOk8zPjE8VSg3uLxwPOb004hdken0D"
  }
}

# The selected mode's publishable key, which ansible-generated delivers to the
# apps that take payments. In the default workspace, which has none, a plan
# fails here.
output "publishable_key" {
  value = local.publishable_keys[terraform.workspace]
}
