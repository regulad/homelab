locals {
  # Whether the selected workspace manages regulad's account, or regubot's.
  # Each account's files enable their blocks only in its workspace, as the other
  # account's token cannot act for it.
  personal = terraform.workspace == "personal"
  bot      = terraform.workspace == "bot"
}

# regulad's SSH public key.
module "shared" {
  source = "../shared"
}
