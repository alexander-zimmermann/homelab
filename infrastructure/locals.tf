###############################################################################
##  Manifest Import & Transformation
###############################################################################
locals {
  ## Raw manifest import
  raw_manifest = merge(
    try(yamldecode(file("${path.module}/manifest/00-globals.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/10-pve.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/20-images.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/30-cloudinit.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/40-templates-vm.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/40-templates-lxc.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/50-fleet-vm.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/50-fleet-lxc.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/60-talos.yaml")), {})
  )

  ## Set defaults settings
  defaults = {
    target_node   = try(local.raw_manifest.global_settings.pve_default_target_node, "pve-1")
    file_storage  = try(local.raw_manifest.global_settings.pve_file_storage, "local")
    block_storage = try(local.raw_manifest.global_settings.pve_block_storage, "local-zfs")
  }

  ## Set transformed manifest (Effective Configuration)
  manifest = {
    pve_configuration   = try(local.raw_manifest.pve_configuration, {})
    images              = try(local.raw_manifest.images, {})
    ci_user_configs     = try(local.raw_manifest.ci_user_configs, {})
    ci_vendor_configs   = try(local.raw_manifest.ci_vendor_configs, {})
    ci_network_configs  = try(local.raw_manifest.ci_network_configs, {})
    ci_meta_configs     = try(local.raw_manifest.ci_meta_configs, {})
    vm_templates        = try(local.raw_manifest.vm_templates, {})
    container_templates = try(local.raw_manifest.container_templates, {})
    virtual_machines    = try(local.raw_manifest.virtual_machines, {})
    containers          = try(local.raw_manifest.containers, {})
    talos_configuration = try(local.raw_manifest.talos_configuration, {})
  }

  ## Shortcuts
  pve_nodes      = try(local.manifest.pve_configuration.cluster_nodes, {})
  pve_connection = try(local.manifest.pve_configuration.connection_configuration, {})
  pve_settings   = try(local.manifest.pve_configuration.node_settings, {})
  pve_acme       = try(local.manifest.pve_configuration.acme_configuration, {})
  pve_network    = try(local.manifest.pve_configuration.network_configuration, {})
  pve_ssh        = try(local.manifest.pve_configuration.ssh_configuration, {})
  pve_users      = try(local.manifest.pve_configuration.user_management.users, {})
  talos_config   = try(local.manifest.talos_configuration, {})
  talos_infra    = try(local.manifest.talos_configuration.infrastructure, {})
}


###############################################################################
##  Virtual machine & container clones creation
###############################################################################
locals {
  ## Expanded map of `virtual_machines` derived from hybrid virtual_machines (map)
  virtual_machines = merge(
    ## Single objects: count == 0
    { for k, spec in local.manifest.virtual_machines : k => {
      template_id    = spec.template_id
      target_node    = try(spec.target_node, local.defaults.target_node)
      vm_id          = spec.vm_id
      wait_for_agent = try(spec.wait_for_agent, true)
      vm_name        = k ## No vm_name field in spec -> use key as name
      disks          = try(spec.disks, [])
      protection     = try(spec.protection, true)
    } if try(spec.count, 0) == 0 },

    ## Batch objects: count > 0
    merge([
      for group_key, spec in local.manifest.virtual_machines : {
        for i in range(1, spec.count + 1) : format("%s_%d", group_key, i) => {
          template_id    = spec.template_id
          target_node    = try(spec.target_node, local.defaults.target_node)
          vm_id          = spec.vm_id_start + i - 1
          wait_for_agent = try(spec.wait_for_agent, true)
          vm_name        = format("%s_%d", group_key, i)
          disks          = try(spec.disks, [])
          protection     = try(spec.protection, true)
        }
      } if try(spec.count, 0) > 0
    ]...)
  )

  ## Expanded map of `containers` derived from hybrid containers (map)
  containers = merge(
    ## Single objects: count == 0
    { for k, spec in local.manifest.containers : k => {
      template_id      = spec.template_id
      target_node      = try(spec.target_node, local.defaults.target_node)
      target_datastore = try(spec.target_datastore, local.defaults.block_storage)
      lxc_id           = spec.lxc_id
      container_name   = k ## No container_name field in spec -> use key as name
      protection       = try(spec.protection, true)
    } if try(spec.count, 0) == 0 },

    ## Batch objects: count > 0
    merge([
      for group_key, spec in local.manifest.containers : {
        for i in range(1, spec.count + 1) : format("%s_%d", group_key, i) => {
          template_id      = spec.template_id
          target_node      = try(spec.target_node, local.defaults.target_node)
          target_datastore = try(spec.target_datastore, local.defaults.block_storage)
          lxc_id           = spec.lxc_id_start + i - 1
          container_name   = format("%s_%d", group_key, i)
          protection       = try(spec.protection, true)
        }
      } if try(spec.count, 0) > 0
    ]...)
  )

  ## Talos control plane node IDs
  control_plane_node_ids = [for k, v in local.virtual_machines : k if startswith(k, "talos_cp_")]

  ## Talos data/worker plane node IDs
  data_plane_node_ids = [for k, v in local.virtual_machines : k if startswith(k, "talos_dp_")]
}
