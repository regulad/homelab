# tutoring: the property, its data retention settings, its web data stream
# Tutoring Website and its key event purchase.
#
# The site is a Google Sites site, whose settings hold the tag; it is still up,
# though its custom domain, tutoring.regulad.xyz, is retired:
# - Published: https://sites.google.com/view/parkerwahle-tutoring/home
# - Editor: https://sites.google.com/d/1hELredflCxuwG0ZwykDF47cnKV4iDvhg/p/12XjV6_BJm6sUqxw1gnpgXL9MXRhl0N_Y/edit
resource "ga4_property" "tutoring" {
  display_name      = "tutoring"
  account           = ga4_account.regulad.id
  time_zone         = "America/New_York"
  currency_code     = "USD"
  industry_category = "JOBS_AND_EDUCATION"
  # Google's user data collection acknowledgement, given on Parker's behalf
  # (2026-11-27), which a Measurement Protocol secret needs. No API reads it
  # back, and it can't be withdrawn.
  acknowledge_user_data_collection = true

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
