# Preserve adopted resource identities when splitting the root into local modules.
# Keep these mappings so existing state and older backups can migrate safely.

moved {
  from = oci_core_instance.bailout
  to   = module.wahlecloud.oci_core_instance.bailout
}

moved {
  from = oci_core_instance.livekit
  to   = module.wahlecloud.oci_core_instance.livekit
}

moved {
  from = oci_core_instance.mail
  to   = module.wahlecloud.oci_core_instance.mail
}

moved {
  from = oci_core_instance.router
  to   = module.wahlecloud.oci_core_instance.router
}

moved {
  from = oci_core_instance.web
  to   = module.legacy.oci_core_instance.web
}

moved {
  from = oci_core_boot_volume.bailout
  to   = module.wahlecloud.oci_core_boot_volume.bailout
}

moved {
  from = oci_core_boot_volume.livekit
  to   = module.wahlecloud.oci_core_boot_volume.livekit
}

moved {
  from = oci_core_boot_volume.mail
  to   = module.wahlecloud.oci_core_boot_volume.mail
}

moved {
  from = oci_core_boot_volume.router
  to   = module.wahlecloud.oci_core_boot_volume.router
}

moved {
  from = oci_core_boot_volume.web
  to   = module.legacy.oci_core_boot_volume.web
}

moved {
  from = oci_core_volume_backup_policy_assignment.livekit
  to   = module.wahlecloud.oci_core_volume_backup_policy_assignment.livekit
}

moved {
  from = oci_core_volume_backup_policy_assignment.mail
  to   = module.wahlecloud.oci_core_volume_backup_policy_assignment.mail
}

moved {
  from = oci_core_volume_backup_policy_assignment.router
  to   = module.wahlecloud.oci_core_volume_backup_policy_assignment.router
}

moved {
  from = oci_core_dhcp_options.legacy_default
  to   = module.legacy.oci_core_dhcp_options.legacy_default
}

moved {
  from = oci_core_dhcp_options.services_default
  to   = module.wahlecloud.oci_core_dhcp_options.services_default
}

moved {
  from = oci_core_dhcp_options.services_public
  to   = module.wahlecloud.oci_core_dhcp_options.services_public
}

moved {
  from = oci_core_internet_gateway.legacy
  to   = module.legacy.oci_core_internet_gateway.legacy
}

moved {
  from = oci_core_internet_gateway.services
  to   = module.wahlecloud.oci_core_internet_gateway.services
}

moved {
  from = oci_core_subnet.legacy
  to   = module.legacy.oci_core_subnet.legacy
}

moved {
  from = oci_core_subnet.services
  to   = module.wahlecloud.oci_core_subnet.services
}

moved {
  from = oci_core_vcn.legacy
  to   = module.legacy.oci_core_vcn.legacy
}

moved {
  from = oci_core_vcn.services
  to   = module.wahlecloud.oci_core_vcn.services
}

moved {
  from = oci_core_route_table.legacy_default
  to   = module.legacy.oci_core_route_table.legacy_default
}

moved {
  from = oci_core_route_table.services_default
  to   = module.wahlecloud.oci_core_route_table.services_default
}

moved {
  from = oci_core_route_table.services_public
  to   = module.wahlecloud.oci_core_route_table.services_public
}

moved {
  from = oci_core_network_security_group.bailout
  to   = module.wahlecloud.oci_core_network_security_group.bailout
}

moved {
  from = oci_core_network_security_group.livekit
  to   = module.wahlecloud.oci_core_network_security_group.livekit
}

moved {
  from = oci_core_network_security_group.mail
  to   = module.wahlecloud.oci_core_network_security_group.mail
}

moved {
  from = oci_core_network_security_group.router
  to   = module.wahlecloud.oci_core_network_security_group.router
}

moved {
  from = oci_core_network_security_group_security_rule.bailout_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.bailout_rule_01
}

moved {
  from = oci_core_network_security_group_security_rule.bailout_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.bailout_rule_02
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_01
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_02
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_03
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_03
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_04
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_04
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_05
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_05
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_06
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_06
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_07
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_07
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_08
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_08
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_09
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_09
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_10
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_10
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_11
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_11
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_12
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_12
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_13
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_13
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_14
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_14
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_01
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_02
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_03
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_03
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_04
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_04
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_05
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_05
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_06
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_06
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_07
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_07
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_08
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_08
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_09
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_09
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_10
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_10
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_11
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_11
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_12
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_12
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_13
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_13
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_14
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_14
}

moved {
  from = oci_core_network_security_group_security_rule.router_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.router_rule_01
}

moved {
  from = oci_core_network_security_group_security_rule.router_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.router_rule_02
}

moved {
  from = oci_core_security_list.legacy_default
  to   = module.legacy.oci_core_security_list.legacy_default
}

moved {
  from = oci_core_security_list.services_default
  to   = module.wahlecloud.oci_core_security_list.services_default
}

moved {
  from = oci_core_security_list.services_public
  to   = module.wahlecloud.oci_core_security_list.services_public
}

moved {
  from = oci_core_ipv6.bailout
  to   = module.wahlecloud.oci_core_ipv6.bailout
}

moved {
  from = oci_core_ipv6.livekit
  to   = module.wahlecloud.oci_core_ipv6.livekit
}

moved {
  from = oci_core_ipv6.mail
  to   = module.wahlecloud.oci_core_ipv6.mail
}

moved {
  from = oci_core_ipv6.router
  to   = module.wahlecloud.oci_core_ipv6.router
}

moved {
  from = oci_core_ipv6.web
  to   = module.legacy.oci_core_ipv6.web
}

moved {
  from = oci_email_dkim.primary
  to   = module.wahlecloud.oci_email_dkim.primary
}

moved {
  from = oci_email_email_domain.primary
  to   = module.wahlecloud.oci_email_email_domain.primary
}

moved {
  from = oci_email_sender.noreply
  to   = module.wahlecloud.oci_email_sender.sender["noreply@regulad.xyz"]
}

moved {
  from = oci_email_sender.personal
  to   = module.wahlecloud.oci_email_sender.sender["regulad@regulad.xyz"]
}

moved {
  from = oci_identity_policy.mail
  to   = module.wahlecloud.oci_identity_policy.mail
}

moved {
  from = data.oci_core_vnic_attachments.bailout
  to   = module.wahlecloud.data.oci_core_vnic_attachments.bailout
}

moved {
  from = data.oci_core_vnic_attachments.livekit
  to   = module.wahlecloud.data.oci_core_vnic_attachments.livekit
}

moved {
  from = data.oci_core_vnic_attachments.mail
  to   = module.wahlecloud.data.oci_core_vnic_attachments.mail
}

moved {
  from = data.oci_core_vnic_attachments.router
  to   = module.wahlecloud.data.oci_core_vnic_attachments.router
}

moved {
  from = data.oci_core_vnic_attachments.web
  to   = module.legacy.data.oci_core_vnic_attachments.web
}
