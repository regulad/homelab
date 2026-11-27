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
  # The user data collection acknowledgement is an action that no API reads
  # back. The provider records an imported property as not acknowledged,
  # false; true would give it on Parker's behalf at the next apply.
  acknowledge_user_data_collection = false

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
