# Shared address ranges for every provider root that connects to the tailnet.
output "tailscale_cidrs" {
  description = "Tailscale address ranges, keyed by IP family."
  value = {
    ipv4 = "100.64.0.0/10"
    ipv6 = "fd7a:115c:a1e0::/48"
  }
}
