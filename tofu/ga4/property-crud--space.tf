# crud-space: the property, its data retention settings, its web data stream
# crud.space and its key event purchase.
resource "ga4_property" "crud_space" {
  display_name  = "crud-space"
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

resource "ga4_data_retention_settings" "crud_space" {
  property                        = ga4_property.crud_space.id
  event_data_retention            = "TWO_MONTHS"
  user_data_retention             = "FOURTEEN_MONTHS"
  reset_user_data_on_new_activity = true

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "ga4_data_stream" "crud_space" {
  display_name = "crud.space"
  property     = ga4_property.crud_space.id
  # The stream has no default URL; an empty one, as Analytics returns it,
  # still marks it a web stream.
  default_uri = ""

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Analytics creates purchase with every web data stream and lets no one
# delete it.
resource "ga4_key_event" "crud_space_purchase" {
  property        = ga4_property.crud_space.id
  event_name      = "purchase"
  counting_method = "ONCE_PER_EVENT"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
