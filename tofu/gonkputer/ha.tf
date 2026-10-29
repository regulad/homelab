# ha: HA rules. Each guest file holds its own HA resource.

locals {
  # The nodes whose CPUs have the x86-64-v3 microarchitecture level.
  amd64v3_nodes = ["prodingus"]

  # Every container with an HA resource: its HA resource ID and its tags, so
  # that rules can select containers by tag. A new container needs its entry
  # here.
  ha_containers = {
    aameter         = { id = proxmox_haresource.aameter.resource_id, tags = proxmox_virtual_environment_container.aameter.tags }
    act             = { id = proxmox_haresource.act.resource_id, tags = proxmox_virtual_environment_container.act.tags }
    authentik       = { id = proxmox_haresource.authentik.resource_id, tags = proxmox_virtual_environment_container.authentik.tags }
    clamd           = { id = proxmox_haresource.clamd.resource_id, tags = proxmox_virtual_environment_container.clamd.tags }
    cordpepperer    = { id = proxmox_haresource.cordpepperer.resource_id, tags = proxmox_virtual_environment_container.cordpepperer.tags }
    freeipa         = { id = proxmox_haresource.freeipa.resource_id, tags = proxmox_virtual_environment_container.freeipa.tags }
    git             = { id = proxmox_haresource.git.resource_id, tags = proxmox_virtual_environment_container.git.tags }
    i2p             = { id = proxmox_haresource.i2p.resource_id, tags = proxmox_virtual_environment_container.i2p.tags }
    immich          = { id = proxmox_haresource.immich.resource_id, tags = proxmox_virtual_environment_container.immich.tags }
    ingress         = { id = proxmox_haresource.ingress.resource_id, tags = proxmox_virtual_environment_container.ingress.tags }
    jenkins         = { id = proxmox_haresource.jenkins.resource_id, tags = proxmox_virtual_environment_container.jenkins.tags }
    mastodon        = { id = proxmox_haresource.mastodon.resource_id, tags = proxmox_virtual_environment_container.mastodon.tags }
    matrix          = { id = proxmox_haresource.matrix.resource_id, tags = proxmox_virtual_environment_container.matrix.tags }
    ncsusplitt      = { id = proxmox_haresource.ncsusplitt.resource_id, tags = proxmox_virtual_environment_container.ncsusplitt.tags }
    nexus           = { id = proxmox_haresource.nexus.resource_id, tags = proxmox_virtual_environment_container.nexus.tags }
    openclaw        = { id = proxmox_haresource.openclaw.resource_id, tags = proxmox_virtual_environment_container.openclaw.tags }
    openwebui       = { id = proxmox_haresource.openwebui.resource_id, tags = proxmox_virtual_environment_container.openwebui.tags }
    peppercord      = { id = proxmox_haresource.peppercord.resource_id, tags = proxmox_virtual_environment_container.peppercord.tags }
    pihole          = { id = proxmox_haresource.pihole.resource_id, tags = proxmox_virtual_environment_container.pihole.tags }
    pterodactyl     = { id = proxmox_haresource.pterodactyl.resource_id, tags = proxmox_virtual_environment_container.pterodactyl.tags }
    qb              = { id = proxmox_haresource.qb.resource_id, tags = proxmox_virtual_environment_container.qb.tags }
    rsshub          = { id = proxmox_haresource.rsshub.resource_id, tags = proxmox_virtual_environment_container.rsshub.tags }
    softether       = { id = proxmox_haresource.softether.resource_id, tags = proxmox_virtual_environment_container.softether.tags }
    tailscalerouter = { id = proxmox_haresource.tailscalerouter.resource_id, tags = proxmox_virtual_environment_container.tailscalerouter.tags }
    timemachine     = { id = proxmox_haresource.timemachine.resource_id, tags = proxmox_virtual_environment_container.timemachine.tags }
    tsexit          = { id = proxmox_haresource.tsexit.resource_id, tags = proxmox_virtual_environment_container.tsexit.tags }
    tvheadend       = { id = proxmox_haresource.tvheadend.resource_id, tags = proxmox_virtual_environment_container.tvheadend.tags }
    uptime          = { id = proxmox_haresource.uptime.resource_id, tags = proxmox_virtual_environment_container.uptime.tags }
    vaultwarden     = { id = proxmox_haresource.vaultwarden.resource_id, tags = proxmox_virtual_environment_container.vaultwarden.tags }
    wako            = { id = proxmox_haresource.wako.resource_id, tags = proxmox_virtual_environment_container.wako.tags }
  }
}

# Containers tagged amd64v3 need x86-64-v3, so they run only on the nodes that
# have it, and stop rather than run anywhere else.
resource "proxmox_harule" "amd64v3" {
  rule      = "amd64v3"
  type      = "node-affinity"
  resources = [for ct in local.ha_containers : ct.id if contains(ct.tags, local.tags.amd64v3)]
  nodes     = { for node in local.amd64v3_nodes : node => null }
  strict    = true
}
