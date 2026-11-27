# regulad: the property, its data retention settings, its web data stream
# regulad.xyz and its key event purchase.
#
# Its data now comes only from the old blog, which GitHub Pages still serves
# from regulad/old-blog (archived), whose _config.yml holds the tag:
# - Site: https://regulad.github.io/old-blog/
# - Source: https://github.com/regulad/old-blog
resource "ga4_property" "regulad" {
  display_name      = "regulad"
  account           = ga4_account.regulad.id
  time_zone         = "America/Los_Angeles"
  currency_code     = "USD"
  industry_category = "OTHER"
  # Google's user data collection acknowledgement, given on Parker's behalf
  # (2026-11-27), which a Measurement Protocol secret needs. No API reads it
  # back, and it can't be withdrawn.
  acknowledge_user_data_collection = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "regulad" {
  property                        = ga4_property.regulad.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "regulad" {
  display_name = "regulad.xyz"
  property     = ga4_property.regulad.id
  default_uri  = "https://regulad.xyz"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "regulad_purchase" {
  property        = ga4_property.regulad.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
