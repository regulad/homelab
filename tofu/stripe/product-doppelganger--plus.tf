# doppelganger-plus: Doppelganger's Plus plan and its monthly price.
resource "stripe_product" "doppelganger_plus" {
  name = "Doppelganger Plus"
}

resource "stripe_price" "doppelganger_plus_monthly" {
  product     = stripe_product.doppelganger_plus.id
  currency    = "usd"
  unit_amount = 999 # $9.99
  # Doppelganger finds the price by its lookup key, which a replacement price
  # takes over as it is created.
  lookup_key          = "doppelganger_plus_monthly"
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
