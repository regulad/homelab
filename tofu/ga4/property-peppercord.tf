# peppercord: the property, its data retention settings, its web data stream
# PepperCord Home and its key event purchase.
resource "ga4_property" "peppercord" {
  display_name      = "peppercord"
  account           = ga4_account.regulad.id
  time_zone         = "America/New_York"
  currency_code     = "USD"
  industry_category = "ONLINE_COMMUNITIES"
  # The user data collection acknowledgement is an action that no API reads
  # back. The provider records an imported property as not acknowledged,
  # false; true would give it on Parker's behalf at the next apply.
  acknowledge_user_data_collection = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "peppercord" {
  property                        = ga4_property.peppercord.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "peppercord" {
  display_name = "PepperCord Home"
  property     = ga4_property.peppercord.id
  default_uri  = "https://www.regulad.xyz/PepperCord"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "peppercord_purchase" {
  property        = ga4_property.peppercord.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
