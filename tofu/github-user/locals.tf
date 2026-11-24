locals {
  # Whether the selected workspace manages regubot's account. Each of its files
  # enables its blocks only there, as the other account's token cannot act for
  # it.
  bot = terraform.workspace == "bot"
}
