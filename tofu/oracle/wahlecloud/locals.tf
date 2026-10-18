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

  # Oracle-defined backup policies, keyed by exact name. These realm-wide IDs
  # belong to no compartment.
  backup_policy_ids = {
    "bronze" = "ocid1.volumebackuppolicy.oc1..aaaaaaaadrzfwjb5tflixtmy5axp2kx65uqakgnupfogabzjhtn5x5dfra6q"
  }

  # Oracle platform images, keyed by exact image name. These regional images are
  # shared across tenancies.
  platform_image_ids = {
    "Oracle-Linux-9.6-2025.11.20-0"         = "ocid1.image.oc1.iad.aaaaaaaaglxne5nh73mxqppl3fkzkqdlda3k22y6oyxcvy6gcaxxsym54mca"
    "Oracle-Linux-9.6-aarch64-2025.11.20-0" = "ocid1.image.oc1.iad.aaaaaaaaa53zducgjvcstvpe76ctctt6ddw5bloq2wvhvboggfs5usyd47za"
    "Oracle-Linux-9.6-aarch64-2025.11.20-1" = "ocid1.image.oc1.iad.aaaaaaaaz3iia6dyo7qkwbkp4crbk6unkjkwg572v553l3rsf4dvsp2teugq"
    "Oracle-Linux-9.8-2026.07.20-1"         = "ocid1.image.oc1.iad.aaaaaaaai4tjt6h3zmwiou6gppgnyjnm3twfqaezcynx6dp3uwr6i2be43cq"
  }
}
