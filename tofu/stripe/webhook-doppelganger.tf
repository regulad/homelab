# doppelganger: the endpoint doppelgangerhq.com receives subscription and
# checkout events at. Live only: production verifies events with the live endpoint's secret,
# so Test mode's would only fail there.
resource "stripe_webhook_endpoint" "doppelganger" {
  count = terraform.workspace == "live" ? 1 : 0

  url = "https://doppelgangerhq.com/api/stripe/webhook"
  # The version Doppelganger's Stripe SDK, stripe-node 23, calls Stripe at. Stripe
  # sets it only when it creates an endpoint, so a new version is a new endpoint,
  # with a new signing secret.
  api_version = "2026-10-28.endive"
  enabled_events = [
    # A completed checkout, which the webhook reports to Google Analytics as a
    # purchase.
    "checkout.session.completed",
    "customer.subscription.created",
    "customer.subscription.updated",
    "customer.subscription.deleted",
  ]

  # A replacement endpoint exists before the old one goes, so events always have
  # an endpoint to go to; those it sends before web.env has its secret fail their
  # signature check and Stripe retries them.
  lifecycle {
    create_before_destroy = true
  }
}

# The endpoint's signing secret, which ansible-generated delivers to
# doppelgangerhq.com's web.env as STRIPE_WEBHOOK_SECRET. Stripe returns it only
# when the endpoint is created; in sandbox it is null.
output "doppelganger_webhook_secret" {
  value     = one(stripe_webhook_endpoint.doppelganger[*].secret)
  sensitive = true
}
