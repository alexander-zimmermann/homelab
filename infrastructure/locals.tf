###############################################################################
##  Manifest import & transformation
###############################################################################
locals {
  ## Raw manifest import
  raw_manifest = merge(
    try(yamldecode(file("${path.module}/manifest/00-cluster/pve-cluster.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/00-cluster/pve-cluster-users.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/00-cluster/pve-cluster-acme.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/10-pve-node/pve-node-core.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/10-pve-node/pve-node-network.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/20-image/image.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/30-cloud-init/cloudinit.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/40-template/template-vm.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/40-template/template-lxc.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/50-fleet/fleet-vm.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/50-fleet/fleet-lxc.yaml")), {}),
    try(yamldecode(file("${path.module}/manifest/60-talos-cluster/talos.yaml")), {})
  )

  ## Set transformed manifest (effective configuration)
  manifest = {
    pve_cluster        = try(local.raw_manifest.pve_cluster, {})
    pve_cluster_users  = try(local.raw_manifest.pve_cluster_users, {})
    pve_cluster_acme   = try(local.raw_manifest.pve_cluster_acme, {})
    pve_node_core      = try(local.raw_manifest.pve_node_core, {})
    pve_node_network   = try(local.raw_manifest.pve_node_network, {})
    image              = try(local.raw_manifest.image, {})
    ci_user_configs    = try(local.raw_manifest.ci_user_configs, {})
    ci_vendor_configs  = try(local.raw_manifest.ci_vendor_configs, {})
    ci_network_configs = try(local.raw_manifest.ci_network_configs, {})
    ci_meta_configs    = try(local.raw_manifest.ci_meta_configs, {})
    template_vm        = try(local.raw_manifest.template_vm, {})
    template_lxc       = try(local.raw_manifest.template_lxc, {})
    fleet_vm           = try(local.raw_manifest.fleet_vm, {})
    fleet_lxc          = try(local.raw_manifest.fleet_lxc, {})
    talos_cluster      = try(local.raw_manifest.talos_cluster, {})
  }

  ## Shortcuts
  defaults = {
    target_node   = try(local.raw_manifest.pve_cluster.defaults.target_node, {})
    file_storage  = try(local.raw_manifest.pve_cluster.defaults.file_storage, {})
    block_storage = try(local.raw_manifest.pve_cluster.defaults.block_storage, {})
  }
  pve_cluster = {
    api   = try(local.manifest.pve_cluster.api_connection, {})
    ssh   = try(local.manifest.pve_cluster.ssh_connection, {})
    nodes = try(local.manifest.pve_cluster.nodes, {})
    users = try(local.manifest.pve_cluster_users.users, {})
    acme  = try(local.manifest.pve_cluster_acme, {})
  }
  pve_node = {
    core = try(local.manifest.pve_node_core, {})
    network = {
      ## Flat list of all network bridge configurations
      bridges = merge([
        for node, config in try(local.manifest.pve_node_network.network_configuration, {}) : {
          for name, params in try(config.bridges, {}) : "${node}_${name}" => merge(params, {
            target_node = node
            name        = name
          })
        }
      ]...)
      ## Flat list of all network bond configurations
      bonds = merge([
        for node, config in try(local.manifest.pve_node_network.network_configuration, {}) : {
          for name, params in try(config.bonds, {}) : "${node}_${name}" => merge(params, {
            target_node = node
            name        = name
          })
        }
      ]...)
      ## Flat list of all network vlan configurations
      vlans = merge([
        for node, config in try(local.manifest.pve_node_network.network_configuration, {}) : {
          for name, params in try(config.vlans, {}) : "${node}_${name}" => merge(params, {
            target_node = node
            name        = name
          })
        }
      ]...)
    }
  }
  talos_config = try(local.manifest.talos_cluster, {})
  talos_infra  = try(local.manifest.talos_cluster.infrastructure, {})
}


###############################################################################
##  Virtual machine & container clones creation
###############################################################################
locals {
  ## Expanded map of `fleet_vm` derived from hybrid fleet_vm (map)
  fleet_vm = merge(
    ## Single objects: count == 0
    { for k, spec in local.manifest.fleet_vm : k => {
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
      for group_key, spec in local.manifest.fleet_vm : {
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

  ## Expanded map of `fleet_lxc` derived from hybrid fleet_lxc (map)
  fleet_lxc = merge(
    ## Single objects: count == 0
    { for k, spec in local.manifest.fleet_lxc : k => {
      template_id      = spec.template_id
      target_node      = try(spec.target_node, local.defaults.target_node)
      target_datastore = try(spec.target_datastore, local.defaults.block_storage)
      lxc_id           = spec.lxc_id
      container_name   = k ## No container_name field in spec -> use key as name
      protection       = try(spec.protection, true)
    } if try(spec.count, 0) == 0 },

    ## Batch objects: count > 0
    merge([
      for group_key, spec in local.manifest.fleet_lxc : {
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
  control_plane_node_ids = [for k, v in local.fleet_vm : k if startswith(k, "talos_cp_")]

  ## Talos data/worker plane node IDs
  data_plane_node_ids = [for k, v in local.fleet_vm : k if startswith(k, "talos_dp_")]
}
