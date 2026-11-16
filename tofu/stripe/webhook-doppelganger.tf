# doppelganger: the endpoint doppelgangerhq.com receives subscription events
# at. Live only: production verifies events with the live endpoint's secret,
# so Test mode's would only fail there.
resource "stripe_webhook_endpoint" "doppelganger" {
  count = terraform.workspace == "live" ? 1 : 0

  url = "https://doppelgangerhq.com/api/stripe/webhook"
  # The version Doppelganger's Stripe SDK is pinned to.
  api_version = "2024-06-20"
  enabled_events = [
    "customer.subscription.created",
    "customer.subscription.updated",
    "customer.subscription.deleted",
  ]
}

# The endpoint's signing secret, which ansible-generated delivers to
# doppelgangerhq.com's web.env as STRIPE_WEBHOOK_SECRET. Stripe returns it only
# when the endpoint is created; in sandbox it is null.
output "doppelganger_webhook_secret" {
  value     = one(stripe_webhook_endpoint.doppelganger[*].secret)
  sensitive = true
}
