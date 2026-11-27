# tutoring: the property, its data retention settings, its web data stream
# Tutoring Website and its key event purchase.
resource "ga4_property" "tutoring" {
  display_name      = "tutoring"
  account           = ga4_account.regulad.id
  time_zone         = "America/New_York"
  currency_code     = "USD"
  industry_category = "JOBS_AND_EDUCATION"
  # The user data collection acknowledgement is an action that no API reads
  # back. The provider records an imported property as not acknowledged,
  # false; true would give it on Parker's behalf at the next apply.
  acknowledge_user_data_collection = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "tutoring" {
  property                        = ga4_property.tutoring.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "tutoring" {
  display_name = "Tutoring Website"
  property     = ga4_property.tutoring.id
  default_uri  = "https://tutoring.regulad.xyz"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "tutoring_purchase" {
  property        = ga4_property.tutoring.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
