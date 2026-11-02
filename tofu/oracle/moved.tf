# Every address this root's resources have had, so older states and backups
# still plan cleanly. The resources began at the root, moved into the child
# modules legacy, wahlecloud and state_backend, and are back at the root, which
# is flat because OpenTofu loads no subdirectories into a module.
#
# A resource whose only move was into its module needs only the move back out:
# states from before the modules already hold its root address. Moves chain
# only between addresses of the same kind, so keyed resources move one instance
# at a time. The senders were two resources before the modules, and wahlecloud
# turned each IPv4/IPv6 pair of numbered NSG rules into one keyed rule; those
# chains run through their former module addresses.

# From module.legacy.

moved {
  from = module.legacy.oci_core_vcn.legacy
  to   = oci_core_vcn.legacy
}

moved {
  from = module.legacy.oci_core_internet_gateway.legacy
  to   = oci_core_internet_gateway.legacy
}

moved {
  from = module.legacy.oci_core_dhcp_options.legacy_default
  to   = oci_core_dhcp_options.legacy_default
}

moved {
  from = module.legacy.oci_core_route_table.legacy_default
  to   = oci_core_route_table.legacy_default
}

moved {
  from = module.legacy.oci_core_security_list.legacy_default
  to   = oci_core_security_list.legacy_default
}

moved {
  from = module.legacy.oci_core_subnet.legacy
  to   = oci_core_subnet.legacy
}

moved {
  from = module.legacy.oci_core_instance.web
  to   = oci_core_instance.web
}

moved {
  from = module.legacy.oci_core_boot_volume.web
  to   = oci_core_boot_volume.web
}

moved {
  from = module.legacy.oci_core_volume_backup_policy_assignment.web
  to   = oci_core_volume_backup_policy_assignment.web
}

moved {
  from = module.legacy.oci_core_ipv6.web
  to   = oci_core_ipv6.web
}

# From module.wahlecloud.

moved {
  from = module.wahlecloud.oci_core_vcn.services
  to   = oci_core_vcn.services
}

moved {
  from = module.wahlecloud.oci_core_internet_gateway.services
  to   = oci_core_internet_gateway.services
}

moved {
  from = module.wahlecloud.oci_core_dhcp_options.services_default
  to   = oci_core_dhcp_options.services_default
}

moved {
  from = module.wahlecloud.oci_core_route_table.services_default
  to   = oci_core_route_table.services_default
}

moved {
  from = module.wahlecloud.oci_core_security_list.services_default
  to   = oci_core_security_list.services_default
}

moved {
  from = module.wahlecloud.oci_core_subnet.services
  to   = oci_core_subnet.services
}

moved {
  from = module.wahlecloud.oci_core_dhcp_options.services_public
  to   = oci_core_dhcp_options.services_public
}

moved {
  from = module.wahlecloud.oci_core_route_table.services_public
  to   = oci_core_route_table.services_public
}

moved {
  from = module.wahlecloud.oci_core_security_list.services_public
  to   = oci_core_security_list.services_public
}

moved {
  from = module.wahlecloud.oci_email_dkim.primary
  to   = oci_email_dkim.primary
}

moved {
  from = module.wahlecloud.oci_email_email_domain.primary
  to   = oci_email_email_domain.primary
}

moved {
  from = oci_email_sender.noreply
  to   = module.wahlecloud.oci_email_sender.sender["noreply@regulad.xyz"]
}

moved {
  from = module.wahlecloud.oci_email_sender.sender["noreply@regulad.xyz"]
  to   = oci_email_sender.sender["noreply@regulad.xyz"]
}

moved {
  from = oci_email_sender.personal
  to   = module.wahlecloud.oci_email_sender.sender["regulad@regulad.xyz"]
}

moved {
  from = module.wahlecloud.oci_email_sender.sender["regulad@regulad.xyz"]
  to   = oci_email_sender.sender["regulad@regulad.xyz"]
}

moved {
  from = module.wahlecloud.oci_identity_policy.mail
  to   = oci_identity_policy.mail
}

moved {
  from = module.wahlecloud.oci_core_instance.bailout
  to   = oci_core_instance.bailout
}

moved {
  from = module.wahlecloud.oci_core_boot_volume.bailout
  to   = oci_core_boot_volume.bailout
}

moved {
  from = module.wahlecloud.oci_core_volume_backup_policy_assignment.bailout
  to   = oci_core_volume_backup_policy_assignment.bailout
}

moved {
  from = module.wahlecloud.oci_core_ipv6.bailout
  to   = oci_core_ipv6.bailout
}

moved {
  from = module.wahlecloud.oci_core_network_security_group.bailout
  to   = oci_core_network_security_group.bailout
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.bailout_rule_01
  to   = oci_core_network_security_group_security_rule.bailout_rule_01
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.bailout_rule_02
  to   = oci_core_network_security_group_security_rule.bailout_rule_02
}

moved {
  from = module.wahlecloud.oci_core_instance.livekit
  to   = oci_core_instance.livekit
}

moved {
  from = module.wahlecloud.oci_core_boot_volume.livekit
  to   = oci_core_boot_volume.livekit
}

moved {
  from = module.wahlecloud.oci_core_volume_backup_policy_assignment.livekit
  to   = oci_core_volume_backup_policy_assignment.livekit
}

moved {
  from = module.wahlecloud.oci_core_ipv6.livekit
  to   = oci_core_ipv6.livekit
}

moved {
  from = module.wahlecloud.oci_core_network_security_group.livekit
  to   = oci_core_network_security_group.livekit
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_01
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_80["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_80["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_80["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_05
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_05
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_05
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_80["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_80["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_80["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_02
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_443["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_443["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_443["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_06
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_06
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_06
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_443["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_443["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_443["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_03
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_03
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_03
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_07
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_07
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_07
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_04
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_04
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_04
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_08
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_08
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_08
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_09
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_09
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_09
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_3478["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_3478["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_udp_3478["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_12
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_12
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_12
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_3478["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_3478["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_udp_3478["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_10
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_10
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_10
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_13
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_13
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_13
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_11
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_11
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_11
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv4"]
  to   = oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_14
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_14
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_rule_14
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv6"]
  to   = oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_instance.mail
  to   = oci_core_instance.mail
}

moved {
  from = module.wahlecloud.oci_core_boot_volume.mail
  to   = oci_core_boot_volume.mail
}

moved {
  from = module.wahlecloud.oci_core_volume_backup_policy_assignment.mail
  to   = oci_core_volume_backup_policy_assignment.mail
}

moved {
  from = module.wahlecloud.oci_core_ipv6.mail
  to   = oci_core_ipv6.mail
}

moved {
  from = module.wahlecloud.oci_core_network_security_group.mail
  to   = oci_core_network_security_group.mail
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_01
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_25["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_25["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_25["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_06
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_06
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_06
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_25["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_25["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_25["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_02
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_143["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_143["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_143["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_07
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_07
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_07
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_143["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_143["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_143["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_03
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_03
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_03
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_465["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_465["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_465["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_08
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_08
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_08
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_465["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_465["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_465["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_04
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_04
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_04
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_587["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_587["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_587["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_09
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_09
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_09
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_587["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_587["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_587["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_05
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_05
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_05
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_993["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_993["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_993["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_10
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_10
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_10
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_993["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_993["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_993["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_11
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_11
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_11
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_4190["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_4190["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_4190["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_12
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_12
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_12
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_4190["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_4190["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_4190["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_13
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_13
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_13
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_80["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_80["ipv4"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_80["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_14
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_14
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_rule_14
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_80["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.mail_tcp_80["ipv6"]
  to   = oci_core_network_security_group_security_rule.mail_tcp_80["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_instance.router
  to   = oci_core_instance.router
}

moved {
  from = module.wahlecloud.oci_core_boot_volume.router
  to   = oci_core_boot_volume.router
}

moved {
  from = module.wahlecloud.oci_core_volume_backup_policy_assignment.router
  to   = oci_core_volume_backup_policy_assignment.router
}

moved {
  from = module.wahlecloud.oci_core_ipv6.router
  to   = oci_core_ipv6.router
}

moved {
  from = module.wahlecloud.oci_core_network_security_group.router
  to   = oci_core_network_security_group.router
}

moved {
  from = oci_core_network_security_group_security_rule.router_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.router_rule_01
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.router_rule_01
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.router_udp_39127["ipv4"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.router_udp_39127["ipv4"]
  to   = oci_core_network_security_group_security_rule.router_udp_39127["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.router_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.router_rule_02
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.router_rule_02
  to   = module.wahlecloud.oci_core_network_security_group_security_rule.router_udp_39127["ipv6"]
}

moved {
  from = module.wahlecloud.oci_core_network_security_group_security_rule.router_udp_39127["ipv6"]
  to   = oci_core_network_security_group_security_rule.router_udp_39127["ipv6"]
}

# From module.state_backend.

moved {
  from = module.state_backend.oci_objectstorage_bucket.state
  to   = oci_objectstorage_bucket.state
}

moved {
  from = module.state_backend.oci_identity_group.state
  to   = oci_identity_group.state
}

moved {
  from = module.state_backend.oci_identity_user.state
  to   = oci_identity_user.state
}

moved {
  from = module.state_backend.oci_identity_user_capabilities_management.state
  to   = oci_identity_user_capabilities_management.state
}

moved {
  from = module.state_backend.oci_identity_user_group_membership.state
  to   = oci_identity_user_group_membership.state
}

moved {
  from = module.state_backend.oci_identity_policy.state
  to   = oci_identity_policy.state
}
