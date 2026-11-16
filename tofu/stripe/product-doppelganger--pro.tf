# doppelganger-pro: Doppelganger's Pro plan and its monthly price.
resource "stripe_product" "doppelganger_pro" {
  name = "Doppelganger Pro"
}

resource "stripe_price" "doppelganger_pro_monthly" {
  product     = stripe_product.doppelganger_pro.id
  currency    = "usd"
  unit_amount = 1499 # $14.99
  # Doppelganger finds the price by its lookup key, which a replacement price
  # takes over as it is created.
  lookup_key          = "doppelganger_pro_monthly"
  transfer_lookup_key = true

  recurring {
    interval = "month"
  }

  # A price's amount cannot change: a new one replaces it, and is made first,
  # so the lookup key always names an active price.
  lifecycle {
    create_before_destroy = true
  }
}
