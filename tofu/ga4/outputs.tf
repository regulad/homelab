# Each property's web stream's measurement ID (G-…), by property name: the tag
# a site loads. It is public, as every page that loads the tag serves it;
# tofu/vercel and ansible-generated deliver it as NEXT_PUBLIC_GA_TAG.
output "measurement_ids" {
  value = {
    doppelganger = ga4_data_stream.doppelganger.measurement_id
    parkerwahle  = ga4_data_stream.parkerwahle.measurement_id
    regulad      = ga4_data_stream.regulad.measurement_id
    tutoring     = ga4_data_stream.tutoring.measurement_id
  }
}
