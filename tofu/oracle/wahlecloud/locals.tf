locals {
  # Preserve the existing plugin states and provider list order.
  agent_plugins = [
    { name = "WebLogic Management Service", desired_state = "DISABLED" },
    { name = "Vulnerability Scanning", desired_state = "DISABLED" },
    { name = "Oracle Java Management Service", desired_state = "DISABLED" },
    { name = "OS Management Hub Agent", desired_state = "DISABLED" },
    { name = "Management Agent", desired_state = "DISABLED" },
    { name = "Fleet Application Management Service", desired_state = "DISABLED" },
    { name = "Custom Logs Monitoring", desired_state = "ENABLED" },
    { name = "Compute RDMA GPU Monitoring", desired_state = "DISABLED" },
    { name = "Compute Instance Run Command", desired_state = "ENABLED" },
    { name = "Compute Instance Monitoring", desired_state = "ENABLED" },
    { name = "Compute HPC RDMA Auto-Configuration", desired_state = "DISABLED" },
    { name = "Compute HPC RDMA Authentication", desired_state = "DISABLED" },
    { name = "Cloud Guard Workload Protection", desired_state = "ENABLED" },
    { name = "Block Volume Management", desired_state = "DISABLED" },
    { name = "Bastion", desired_state = "DISABLED" },
  ]
}
