# doppelganger: Doppelganger's customer portal configuration, whose ID the app
# passes when it opens the portal for a customer. Customers see their invoices,
# update their payment method, cancel at the period's end, and switch between
# Plus and Pro with prorations.
resource "stripe_billing_portal_configuration" "doppelganger" {
  default_return_url = "https://doppelgangerhq.com/user"

  business_profile = {
    privacy_policy_url   = "https://doppelgangerhq.com/privacy"
    terms_of_service_url = "https://doppelgangerhq.com/tos"
  }

  features = {
    customer_update = {
      enabled = false
    }
    invoice_history = {
      enabled = true
    }
    payment_method_update = {
      enabled = true
    }
    subscription_cancel = {
      enabled = true
      mode    = "at_period_end"
    }
    subscription_update = {
      enabled                 = true
      default_allowed_updates = ["price"]
      proration_behavior      = "create_prorations"
      products = [
        {
          product = stripe_product.doppelganger_plus.id
          prices  = [stripe_price.doppelganger_plus_monthly.id]
        },
        {
          product = stripe_product.doppelganger_pro.id
          prices  = [stripe_price.doppelganger_pro_monthly.id]
        },
      ]
    }
  }
}

# The configuration's ID, which ansible-generated delivers to doppelgangerhq.com's
# web.env as STRIPE_PORTAL_CONFIGURATION.
output "doppelganger_portal_configuration" {
  value = stripe_billing_portal_configuration.doppelganger.id
}
