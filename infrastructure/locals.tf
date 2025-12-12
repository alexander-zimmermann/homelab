###############################################################################
##  Talos cluster creation
###############################################################################
locals {

  ## Expanded map of `virtual_machines` derived from hybrid virtual_machines (map)
  virtual_machines = merge(
    ## Single objects: count == 0
    { for k, spec in var.virtual_machines : k => {
      template_id    = spec.template_id
      target_node    = spec.target_node
      vm_id          = spec.vm_id
      wait_for_agent = spec.wait_for_agent
      vm_name        = k ## No vm_name field in spec -> use key as name
      disks          = try(spec.disks, [])
    } if try(spec.count, 0) == 0 },

    ## Batch objects: count > 0
    merge([
      for group_key, spec in var.virtual_machines : {
        for i in range(1, spec.count + 1) : format("%s_%d", group_key, i) => {
          template_id    = spec.template_id
          target_node    = spec.target_node
          vm_id          = spec.vm_id_start + i - 1
          wait_for_agent = try(spec.wait_for_agent, true)
          vm_name        = format("%s_%d", group_key, i)
          disks          = try(spec.disks, [])
        }
      } if try(spec.count, 0) > 0
    ]...)
  )

  ## Expanded map of `containers` derived from hybrid containers (map)
  containers = merge(
    ## Single objects: count == 0
    { for k, spec in var.containers : k => {
      template_id      = spec.template_id
      target_node      = spec.target_node
      target_datastore = spec.target_datastore
      lxc_id           = spec.lxc_id
      container_name   = k ## No container_name field in spec -> use key as name
    } if try(spec.count, 0) == 0 },

    ## Batch objects: count > 0
    merge([
      for group_key, spec in var.containers : {
        for i in range(1, spec.count + 1) : format("%s_%d", group_key, i) => {
          template_id      = spec.template_id
          target_node      = spec.target_node
          target_datastore = spec.target_datastore
          lxc_id           = spec.lxc_id_start + i - 1
          container_name   = format("%s_%d", group_key, i)
        }
      } if try(spec.count, 0) > 0
    ]...)
  )

  ## Talos control plane node IDs
  control_plane_node_ids = [for k, v in local.virtual_machines : k if startswith(k, "talos_cp_")]

  ## Talos data/worker plane node IDs
  data_plane_node_ids = [for k, v in local.virtual_machines : k if startswith(k, "talos_dp_")]
}
