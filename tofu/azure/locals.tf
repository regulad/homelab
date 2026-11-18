locals {
  # The directory, its one subscription, and the application this root signs in
  # as (see README.md).
  tenant_id       = "a693ff78-50c2-4d7a-aaa1-96e3060797d6"
  subscription_id = "d40261cd-31ec-401e-a0c6-791792f048cb"
  client_id       = "76130b9f-7f01-4953-bc94-6032540a2c0a"

  # Parker Wahle, the directory's one user, by object ID.
  parker_object_id = "c2e80979-83b2-449e-a4ce-487b334bf101"
}
