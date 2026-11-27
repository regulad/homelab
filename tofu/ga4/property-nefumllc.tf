# nefumllc: the property, its data retention settings, its web data stream
# www.nefumllc.com and its key events purchase, close_convert_lead and
# qualify_lead.
resource "ga4_property" "nefumllc" {
  display_name      = "nefumllc"
  account           = ga4_account.regulad.id
  time_zone         = "America/New_York"
  currency_code     = "USD"
  industry_category = "INTERNET_AND_TELECOM"
  # The user data collection acknowledgement is an action that no API reads
  # back. The provider records an imported property as not acknowledged,
  # false; true would give it on Parker's behalf at the next apply.
  acknowledge_user_data_collection = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "nefumllc" {
  property                        = ga4_property.nefumllc.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "nefumllc" {
  display_name = "www.nefumllc.com"
  property     = ga4_property.nefumllc.id
  default_uri  = "https://www.nefumllc.com"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "nefumllc_purchase" {
  property        = ga4_property.nefumllc.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_key_event" "nefumllc_close_convert_lead" {
  property        = ga4_property.nefumllc.id
  event_name      = "close_convert_lead"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_key_event" "nefumllc_qualify_lead" {
  property        = ga4_property.nefumllc.id
  event_name      = "qualify_lead"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
