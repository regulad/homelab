locals {
  # ingress's inventory name, which the tailnet's DNS also resolves, and its
  # login users and directories, as ansible-generated declares them:
  # kodi-plugins publishes as kodi-publish into kodi.regulad.xyz's web root.
  ingress_host = "ingress.regulad.internal"
  ingress      = yamldecode(file("${path.module}/../../ansible-generated/inventory/host_vars/${local.ingress_host}/main.yml"))
  kodi_publish = {
    host = local.ingress_host
    user = one([for u in local.ingress.host_files_login_users : u.name if u.name == "kodi-publish"])
    root = one([for d in local.ingress.host_files_directories : d.path if try(d.owner, null) == "kodi-publish"])
  }

  # Nexus's own users as Ansible declares them, by user ID. The CI logins'
  # names are read from there, so each is written once, and naming a user
  # Ansible does not declare fails the plan.
  nexus_users = {
    for user in yamldecode(file("${path.module}/../../ansible-generated/inventory/group_vars/nexus_servers.yml")).nexus_security_users :
    user.userId => user
  }

  # Jenkins's service users as Ansible declares them, by name, likewise.
  jenkins_users = {
    for user in yamldecode(file("${path.module}/../../ansible-generated/inventory/host_vars/jenkins.regulad.internal/main.yml")).jenkins_freeipa_service_users :
    user.name => user
  }
}
