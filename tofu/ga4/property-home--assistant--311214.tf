# home-assistant-311214: the property, its data retention settings and its
# Firebase link.
resource "ga4_property" "home_assistant_311214" {
  display_name  = "home-assistant-311214"
  account       = ga4_account.regulad.id
  time_zone     = "America/Los_Angeles"
  currency_code = "USD"
  # No industry category is set, and the provider leaves an undeclared one as
  # it is.
  # The user data collection acknowledgement is an action that no API reads
  # back. The provider records an imported property as not acknowledged,
  # false; true would give it on Parker's behalf at the next apply.
  acknowledge_user_data_collection = false

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_retention_settings" "home_assistant_311214" {
  property                        = ga4_property.home_assistant_311214.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_firebase_link" "home_assistant_311214" {
  property = ga4_property.home_assistant_311214.id
  project  = "projects/745175328240" # home-assistant-311214, by number, the form Analytics returns

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
