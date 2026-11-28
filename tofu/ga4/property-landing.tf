# landing: the property, its data retention settings, its web data stream
# Parker Wahle and its key event purchase.
resource "ga4_property" "landing" {
  display_name      = "landing"
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

resource "ga4_data_retention_settings" "landing" {
  property                        = ga4_property.landing.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "landing" {
  display_name = "Parker Wahle"
  property     = ga4_property.landing.id
  default_uri  = "https://regulad.net"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "landing_purchase" {
  property        = ga4_property.landing.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
