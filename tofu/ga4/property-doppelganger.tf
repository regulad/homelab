# doppelganger: the property, its data retention settings, its web data stream
# doppelgangerhq.com and its key event purchase.
#
# Doppelganger's web app sends to it:
# - Source: https://github.com/regulad/doppelganger (apps/web/src/app/layout.tsx)
# - Site: https://doppelgangerhq.com
resource "ga4_property" "doppelganger" {
  display_name      = "doppelganger"
  account           = ga4_account.regulad.id
  time_zone         = "America/Los_Angeles"
  currency_code     = "USD"
  industry_category = "TECHNOLOGY"
  # Google's user data collection acknowledgement, given on Parker's behalf
  # (2026-11-27), which a Measurement Protocol secret needs. No API reads it
  # back, and it can't be withdrawn.
  acknowledge_user_data_collection = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "doppelganger" {
  property                        = ga4_property.doppelganger.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "doppelganger" {
  display_name = "doppelgangerhq.com"
  property     = ga4_property.doppelganger.id
  default_uri  = "https://www.doppelgangerhq.com"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "doppelganger_purchase" {
  property        = ga4_property.doppelganger.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# A new account, which the web app sends as sign_up, GA4's recommended event,
# with its method (email, or the provider of a first sign-in).
resource "ga4_key_event" "doppelganger_sign_up" {
  property        = ga4_property.doppelganger.id
  event_name      = "sign_up"
  counting_method = "ONCE_PER_EVENT"
}

# The server's Measurement Protocol secret, with which doppelganger's Stripe
# webhook reports each purchase. Delivered to doppelgangerhq.com's server
# environment as GA_MEASUREMENT_PROTOCOL_SECRET by ansible-generated.
resource "ga4_measurement_protocol_secret" "doppelganger" {
  data_stream  = ga4_data_stream.doppelganger.id
  display_name = "doppelgangerhq.com server"

  # Analytics refuses a secret until the property's acknowledgement is given.
  depends_on = [ga4_property.doppelganger]
}
