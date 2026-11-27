# The deleted properties' children, which went with them: they leave state
# without a call of their own, as Analytics refuses to delete a property's
# built-in purchase key event. To be removed after the deletion apply.

removed {
  from = ga4_data_retention_settings.crud_space

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_stream.crud_space

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.crud_space_purchase

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_retention_settings.uc2_landing

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_stream.uc2_landing

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.uc2_landing_purchase

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_retention_settings.ti_testnav

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_stream.ti_testnav

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.ti_testnav_purchase

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_retention_settings.uulanding

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_stream.uulanding

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_custom_dimension.uulanding_type

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_custom_dimension.uulanding_query

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.uulanding_purchase

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.uulanding_search

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_retention_settings.nefumllc

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_data_stream.nefumllc

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.nefumllc_purchase

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.nefumllc_close_convert_lead

  lifecycle {
    destroy = false
  }
}

removed {
  from = ga4_key_event.nefumllc_qualify_lead

  lifecycle {
    destroy = false
  }
}
