"""reverse_zone: the in-addr.arpa or ip6.arpa zone of a network.

'10.23.0.0/16' | reverse_zone is '23.10.in-addr.arpa', and a /64 gives its
16-nibble ip6.arpa zone. The prefix must fall on an octet (IPv4) or nibble
(IPv6) boundary, as a reverse zone does.
"""

import ipaddress

from ansible.errors import AnsibleFilterError


def reverse_zone(network):
    net = ipaddress.ip_network(network, strict=False)
    step = 8 if net.version == 4 else 4
    if net.prefixlen % step:
        raise AnsibleFilterError(f"reverse_zone: {network} is not on a {step}-bit boundary")
    labels = net.network_address.reverse_pointer.split('.')
    # reverse_pointer names the whole address; keep the network's labels.
    host_labels = (net.max_prefixlen - net.prefixlen) // step
    return '.'.join(labels[host_labels:])


class FilterModule:
    def filters(self):
        return {'reverse_zone': reverse_zone}
