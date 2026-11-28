# moved: every past address move, so old states and backups still plan cleanly.

# regulad/parkerwahle became regulad/landing, and its property took the new name.
moved {
  from = ga4_property.parkerwahle
  to   = ga4_property.landing
}

moved {
  from = ga4_data_retention_settings.parkerwahle
  to   = ga4_data_retention_settings.landing
}

moved {
  from = ga4_data_stream.parkerwahle
  to   = ga4_data_stream.landing
}

moved {
  from = ga4_key_event.parkerwahle_purchase
  to   = ga4_key_event.landing_purchase
}
