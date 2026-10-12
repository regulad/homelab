locals {
  # Preserve the existing plugin states and provider list order.
  agent_plugins = [
    { name = "Vulnerability Scanning", desired_state = "DISABLED" },
    { name = "Management Agent", desired_state = "DISABLED" },
    { name = "Custom Logs Monitoring", desired_state = "ENABLED" },
    { name = "Compute RDMA GPU Monitoring", desired_state = "DISABLED" },
    { name = "Compute Instance Monitoring", desired_state = "ENABLED" },
    { name = "Compute HPC RDMA Auto-Configuration", desired_state = "DISABLED" },
    { name = "Compute HPC RDMA Authentication", desired_state = "DISABLED" },
    { name = "Cloud Guard Workload Protection", desired_state = "ENABLED" },
    { name = "Block Volume Management", desired_state = "DISABLED" },
    { name = "Bastion", desired_state = "DISABLED" },
  ]
}
