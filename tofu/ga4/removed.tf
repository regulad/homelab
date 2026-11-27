# The deleted property's children, which went with it: they leave state
# without a call of their own, as Analytics refuses to delete a property's
# built-in purchase key event. To be removed after the deletion apply.

removed {
  from = ga4_data_retention_settings.doppelganger

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_stream.doppelganger

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.doppelganger_purchase

  lifecycle {
    destroy = false
  }
}
