# Preserve rule IDs when consolidating IPv4/IPv6 pairs.
# These moves chain after the root-to-module mappings.

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_01
  to   = oci_core_network_security_group_security_rule.livekit_tcp_80["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_05
  to   = oci_core_network_security_group_security_rule.livekit_tcp_80["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_02
  to   = oci_core_network_security_group_security_rule.livekit_tcp_443["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_06
  to   = oci_core_network_security_group_security_rule.livekit_tcp_443["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_03
  to   = oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_07
  to   = oci_core_network_security_group_security_rule.livekit_tcp_7881["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_04
  to   = oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_08
  to   = oci_core_network_security_group_security_rule.livekit_tcp_5349["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_09
  to   = oci_core_network_security_group_security_rule.livekit_udp_3478["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_12
  to   = oci_core_network_security_group_security_rule.livekit_udp_3478["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_10
  to   = oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_13
  to   = oci_core_network_security_group_security_rule.livekit_udp_30000_40000["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_11
  to   = oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.livekit_rule_14
  to   = oci_core_network_security_group_security_rule.livekit_udp_50000_60000["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_01
  to   = oci_core_network_security_group_security_rule.mail_tcp_25["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_06
  to   = oci_core_network_security_group_security_rule.mail_tcp_25["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_02
  to   = oci_core_network_security_group_security_rule.mail_tcp_143["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_07
  to   = oci_core_network_security_group_security_rule.mail_tcp_143["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_03
  to   = oci_core_network_security_group_security_rule.mail_tcp_465["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_08
  to   = oci_core_network_security_group_security_rule.mail_tcp_465["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_04
  to   = oci_core_network_security_group_security_rule.mail_tcp_587["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_09
  to   = oci_core_network_security_group_security_rule.mail_tcp_587["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_05
  to   = oci_core_network_security_group_security_rule.mail_tcp_993["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_10
  to   = oci_core_network_security_group_security_rule.mail_tcp_993["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_11
  to   = oci_core_network_security_group_security_rule.mail_tcp_4190["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_12
  to   = oci_core_network_security_group_security_rule.mail_tcp_4190["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_13
  to   = oci_core_network_security_group_security_rule.mail_tcp_80["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.mail_rule_14
  to   = oci_core_network_security_group_security_rule.mail_tcp_80["ipv6"]
}

moved {
  from = oci_core_network_security_group_security_rule.router_rule_01
  to   = oci_core_network_security_group_security_rule.router_udp_39127["ipv4"]
}

moved {
  from = oci_core_network_security_group_security_rule.router_rule_02
  to   = oci_core_network_security_group_security_rule.router_udp_39127["ipv6"]
}
