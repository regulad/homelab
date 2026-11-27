# uulanding: the property, its data retention settings, its web data stream
# UULanding Vercel Host, its custom dimensions type and query and its key
# events purchase and search.
resource "ga4_property" "uulanding" {
  display_name      = "uulanding"
  account           = ga4_account.regulad.id
  time_zone         = "America/New_York"
  currency_code     = "USD"
  industry_category = "OTHER"
  # The user data collection acknowledgement is an action that no API reads
  # back. The provider records an imported property as not acknowledged,
  # false; true would give it on Parker's behalf at the next apply.
  acknowledge_user_data_collection = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "uulanding" {
  property                        = ga4_property.uulanding.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "uulanding" {
  display_name = "UULanding Vercel Host"
  property     = ga4_property.uulanding.id
  default_uri  = "https://uulanding.vercel.app"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_custom_dimension" "uulanding_type" {
  display_name   = "Proxy Type"
  property       = ga4_property.uulanding.id
  parameter_name = "type"
  scope          = "EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_custom_dimension" "uulanding_query" {
  display_name   = "Search Query"
  property       = ga4_property.uulanding.id
  parameter_name = "query"
  scope          = "EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "uulanding_purchase" {
  property        = ga4_property.uulanding.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_key_event" "uulanding_search" {
  property        = ga4_property.uulanding.id
  event_name      = "search"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
