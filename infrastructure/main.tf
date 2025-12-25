###############################################################################
## PVE node configuration
###############################################################################
module "pve_nodes" {
  source   = "./modules/pve_nodes"
  for_each = var.pve_nodes

  ## SSH connection (required for local content type changes)
  ssh_hostname    = var.pve_nodes[each.key].address
  ssh_username    = var.pve_ssh_username
  ssh_private_key = var.pve_ssh_private_key

  ## PVE node configuration
  node                = each.key
  local_content_types = var.local_content_types
  timezone            = var.timezone
  dns_servers         = var.dns_servers
  dns_search_domain   = var.dns_search_domain
}


###############################################################################
## PVE user management
###############################################################################
module "pve_user_mgmt" {
  source   = "./modules/pve_user_mgmt"
  for_each = var.users

  ## User identity and authentication
  username   = each.key
  password   = each.value.password
  realm      = each.value.realm
  enabled    = each.value.enabled
  first_name = each.value.first_name
  last_name  = each.value.last_name
  email      = each.value.email
  comment    = each.value.comment

  ## Role and permissions
  role_id         = each.value.role_id
  create_role     = each.value.create_role
  role_privileges = each.value.role_privileges

  ## Token configuration
  create_token          = each.value.create_token
  token_name            = each.value.token_name
  privileges_separation = each.value.privileges_separation

  ## ACL configuration
  path      = each.value.path
  propagate = each.value.propagate
}


###############################################################################
## PVE certificate management
###############################################################################
module "pve_acme" {
  source = "./modules/pve_acme"

  ## Pass the aliased provider to satisfy the state reference
  providers = {
    proxmox.root = proxmox.root
  }

  ## SSH connection (required for acme changes)
  ssh_hostname    = var.pve_nodes[var.acme_target_node].address
  ssh_username    = var.pve_ssh_username
  ssh_private_key = var.pve_ssh_private_key

  ## ACME account configuration
  cert_domains  = var.acme_cert_domains
  contact_email = var.acme_contact_email
  cf_token      = var.cf_token
  cf_zone_id    = var.cf_zone_id
  cf_account_id = var.cf_account_id
}

###############################################################################
## PVE network configuration
###############################################################################
module "pve-bond" {
  source      = "./modules/pve_network"
  for_each    = var.bonds
  create_bond = true

  ## SSH connection (required for network changes)
  ssh_hostname    = var.pve_nodes[each.value.target_node].address
  ssh_username    = var.pve_ssh_username
  ssh_private_key = var.pve_ssh_private_key

  ## Node placement
  name = each.key
  node = each.value.target_node

  ## Bonding configuration
  mode        = each.value.mode
  slaves      = each.value.slaves
  miimon      = each.value.miimon
  lacp_rate   = each.value.lacp_rate
  hash_policy = each.value.hash_policy
  primary     = each.value.primary

  ## Network configuration
  mtu      = each.value.mtu
  address  = each.value.address
  address6 = each.value.address6
  gateway  = each.value.gateway
  gateway6 = each.value.gateway6

  ## Interface options
  autostart = each.value.autostart
  comment   = each.value.comment
}

module "pve-vlan" {
  source      = "./modules/pve_network"
  for_each    = var.vlans
  create_vlan = true

  ## Node placement
  name = each.key
  node = each.value.target_node

  ## VLAN configuration
  interface = each.value.interface
  vlan      = each.value.vlan

  ## Network configuration
  address  = each.value.address
  address6 = each.value.address6
  gateway  = each.value.gateway
  gateway6 = each.value.gateway6
  mtu      = each.value.mtu

  ## Interface options
  autostart = each.value.autostart
  comment   = each.value.comment
}

module "pve-bridge" {
  source        = "./modules/pve_network"
  for_each      = var.bridges
  create_bridge = true

  ## Node placement
  name = each.key
  node = each.value.target_node

  ## Bridge configuration
  ports      = each.value.ports
  vlan_aware = each.value.vlan_aware

  ## Network configuration
  address  = each.value.address
  address6 = each.value.address6
  gateway  = each.value.gateway
  gateway6 = each.value.gateway6
  mtu      = each.value.mtu

  ## Interface options
  autostart = each.value.autostart
  comment   = each.value.comment
}


###############################################################################
## Virtual machine & container images
###############################################################################
module "image" {
  source   = "./modules/image"
  for_each = local.manifest.images

  ## Storage configuration
  node      = try(each.value.target_node, local.defaults.target_node)
  datastore = try(each.value.target_datastore, local.defaults.file_storage)

  ## Image source and verification
  image_filename           = each.value.image_filename
  image_url                = each.value.image_url
  image_checksum           = each.value.image_checksum
  image_checksum_algorithm = try(each.value.image_checksum_algorithm, "sha256")
  image_type               = each.value.image_type
}


###############################################################################
##  VM cloud-init configuration
###############################################################################
module "vm_ci_user_config" {
  source             = "./modules/vm_cloud-init"
  for_each           = local.manifest.ci_user_configs
  create_user_config = true

  ## Storage configuration
  node      = try(each.value.target_node, local.defaults.target_node)
  datastore = try(each.value.target_datastore, local.defaults.file_storage)
  filename  = "${each.key}-user-config.yaml"

  ## User account configuration
  username       = each.value.username
  ssh_public_key = each.value.ssh_public_key
  password       = each.value.password
  set_password   = each.value.set_password
}

module "vm_ci_vendor_config" {
  source               = "./modules/vm_cloud-init"
  for_each             = local.manifest.ci_vendor_configs
  create_vendor_config = true

  ## Storage configuration
  node      = try(each.value.target_node, local.defaults.target_node)
  datastore = try(each.value.target_datastore, local.defaults.file_storage)
  filename  = "${each.key}-vendor-config.yaml"

  ## Package management
  packages       = try(each.value.packages, [])
  package_update = try(each.value.package_update, true)

  ## Custom commands
  runcmd = try(each.value.runcmd, [])
}

module "vm_ci_network_config" {
  source                = "./modules/vm_cloud-init"
  for_each              = local.manifest.ci_network_configs
  create_network_config = true

  ## Storage configuration
  node      = try(each.value.target_node, local.defaults.target_node)
  datastore = try(each.value.target_datastore, local.defaults.file_storage)
  filename  = "${each.key}-network-config.yaml"

  ## DHCP configuration
  dhcp4     = each.value.dhcp4
  dhcp6     = each.value.dhcp6
  accept_ra = each.value.accept_ra

  ## Static IP configuration
  ipv4_address = try(each.value.ipv4_address, "")
  ipv6_address = try(each.value.ipv6_address, "")
  gateway4     = try(each.value.ipv4_gateway, "")
  gateway6     = try(each.value.ipv6_gateway, "")

  ## DNS configuration
  dns_servers       = try(each.value.dns_servers, ["1.1.1.1", "2606:4700:4700::1111"])
  dns_search_domain = try(each.value.dns_search_domain, [])
}

module "vm_ci_meta_config" {
  source             = "./modules/vm_cloud-init"
  for_each           = local.manifest.ci_meta_configs
  create_meta_config = true

  ## Storage configuration
  node      = try(each.value.target_node, local.defaults.target_node)
  datastore = try(each.value.target_datastore, local.defaults.file_storage)
  filename  = "${each.key}-meta-config.yaml"

  ## System identity
  hostname = each.value.hostname
}


###############################################################################
##  Virtual machine & container templates
###############################################################################
module "vm_template" {
  source   = "./modules/vm_template"
  for_each = local.manifest.vm_templates

  ## Infrastructure placement
  node           = try(each.value.target_node, local.defaults.target_node)
  disk_datastore = try(each.value.target_datastore, local.defaults.block_storage)

  ## VM identification
  name        = "${each.key}-template"
  vm_id       = each.value.vm_id
  description = "${try(each.value.description, "Created by Terraform")} - Created on ${timestamp()}"
  tags        = try(each.value.tags, ["opentofu", "template", "vm"])

  ## Hardware configuration
  bios         = try(each.value.bios, "seabios")
  machine_type = lookup(each.value, "machine_type", null)
  cores        = each.value.cores
  memory       = each.value.memory

  ## Disk and image configuration
  image_id  = try(module.image[each.value.image_id].image_id, null)
  os_type   = each.value.os_type
  disk_size = each.value.disk_size

  ## Cloud-init configuration
  enable_cloud_init = lookup(each.value, "enable_cloud_init", true)
  ci_user_data      = try(module.vm_ci_user_config[each.value.ci_user_data_id].user_data_file_id, null)
  ci_vendor_data    = try(module.vm_ci_vendor_config[each.value.ci_vendor_data_id].vendor_data_file_id, null)
  ci_network_data   = try(module.vm_ci_network_config[each.value.ci_network_data_id].network_data_file_id, null)
  ci_meta_data      = try(module.vm_ci_meta_config[each.value.ci_meta_data_id].meta_data_file_id, null)

  ## Security and UEFI configuration (Windows 11 / modern OS)
  enable_tpm  = lookup(each.value, "enable_tpm", false)
  secure_boot = lookup(each.value, "secure_boot", false)
}

module "container_template" {
  source   = "./modules/container_template"
  for_each = local.manifest.container_templates

  ## Infrastructure placement
  node           = try(each.value.target_node, local.defaults.target_node)
  disk_datastore = try(each.value.target_datastore, local.defaults.block_storage)

  ## Container identification
  name         = "${each.key}-template"
  lxc_id       = each.value.lxc_id
  description  = "${try(each.value.description, "Created by Terraform")} - Created on ${timestamp()}"
  tags         = try(each.value.tags, ["opentofu", "template", "lxc"])
  unprivileged = try(each.value.unprivileged, true)
  image_id     = try(module.image[each.value.image_id].image_id, null)

  ## Resource allocation
  cores       = each.value.cores
  memory      = each.value.memory
  memory_swap = try(each.value.memory_swap, 512)
  disk_size   = each.value.disk_size

  ## Operating system configuration
  os_type = each.value.os_type

  ## Network configuration
  vnic_name         = try(each.value.vnic_name, "eth0")
  vnic_bridge       = try(each.value.vnic_bridge, "vmbr0")
  vlan_tag          = try(each.value.vlan_tag, null)
  dns_servers       = try(each.value.dns_servers, ["1.1.1.1", "2606:4700:4700::1111"])
  dns_search_domain = try(each.value.dns_search_domain, [])
}


###############################################################################
##  Virtual machine & container clones
###############################################################################
module "virtual_machines" {
  source   = "./modules/vm_clone"
  for_each = local.virtual_machines

  ## VM placement and identification
  node  = each.value.target_node
  vm_id = each.value.vm_id
  name  = each.value.vm_name

  ## Used VM template
  template_id   = module.vm_template[each.value.template_id].vmid
  template_node = module.vm_template[each.value.template_id].node

  ## Startup variables
  wait_for_agent = each.value.wait_for_agent
  protection     = each.value.protection

  ## Additional disks
  disks = [
    for d in try(each.value.disks, []) : merge(d, {
      disk_datastore = try(d.disk_datastore, local.defaults.block_storage)
    })
  ]
}

module "containers" {
  source   = "./modules/container_clone"
  for_each = local.containers

  ## Container placement and identification
  node      = each.value.target_node
  datastore = each.value.target_datastore
  lxc_id    = each.value.lxc_id
  name      = each.value.container_name

  ## Used vontainer template
  template_id   = module.container_template[each.value.template_id].lxc_id
  template_node = module.container_template[each.value.template_id].node

  ## Startup variables
  protection = each.value.protection
}


###############################################################################
##  Talos cluster
###############################################################################
module "talos_cluster" {
  source = "./modules/talos-cluster"

  ## Cluster identity
  cluster_name = local.manifest.talos_configuration.cluster_name

  ## Talos/Kubernetes versions
  talos_version      = local.manifest.talos_configuration.talos_version
  kubernetes_version = local.manifest.talos_configuration.kubernetes_version

  ## Node topology
  cluster_head  = module.virtual_machines[local.control_plane_node_ids[0]].ipv4[0]
  control_plane = [for id in local.control_plane_node_ids : module.virtual_machines[id].ipv4[0]]
  data_plane    = [for id in local.data_plane_node_ids : module.virtual_machines[id].ipv4[0]]

  ## Network configuration
  dns_servers = var.talos_dns_servers
  ntp_servers = var.talos_ntp_servers

  ## Dataplane storage
  longhorn_disk_selector_match = var.talos_longhorn.disk_selector_match
  longhorn_mount_path          = var.talos_longhorn.mount_path
  longhorn_filesystem          = var.talos_longhorn.filesystem
}
